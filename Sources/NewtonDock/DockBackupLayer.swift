
import NSOF


private struct SoupInfo {
    let name: String
    let signature: Int32
}

private struct StoresProgress {
    let current: NewtonFrame
    let remaining: [NewtonFrame]
}

private struct SoupsProgress {
    let current: SoupInfo
    let remaining: [SoupInfo]
    let storesProgress: StoresProgress
}

private struct SoupProgress {
    let current: UInt32
    let remaining: [UInt32]
    let soupsProgress: SoupsProgress
}

public class DockBackupLayer {

    public enum Error: Swift.Error {
        case notConnected
        case notActive
        case invalidSyncOptions
        case invalidStoreFrame
    }

    private enum State {
        case inactive
        case requestedSync
        case requestedSyncOptions
        case setStore(StoresProgress)
        case setSoup(SoupsProgress)
        case requestedSoupIDs(SoupsProgress)
        case requestedEntry(SoupProgress)
    }

    private static let supportedSoups = ["Notes", "Calendar"]

    internal weak var connectionLayer: DockConnectionLayer!

    private var state: State = .inactive

    private func write(packet: EncodableDockPacket) throws {
        try connectionLayer.write(packet: packet)
    }

    internal func start() throws {
        guard case .inactive = state else {
            return
        }
        if connectionLayer.state == .backingUp {
            return
        }

        guard connectionLayer.state == .connected else {
            throw Error.notConnected
        }

        try connectionLayer.startDesktopControl()
        try write(packet: RequestToSyncPacket())
        state = .requestedSync
    }

    public func handleRequest() throws {
        try write(packet: GetSyncOptionsPacket())
        state = .requestedSyncOptions
    }

    public func handleDisconnect() {
        state = .inactive
    }

    private func sendError() throws {
        // TODO: or protocolError?
        try write(packet: ResultPacket(error: .desktopError))
        state = .inactive
    }

    // TODO: to request the time the current store was last backed up:
    // `try write(packet: LastSyncTimePacket())`
    // Newton will respond with `CurrentTimePacket`

    public func read(packet: DecodableDockPacket) throws {

        if packet is OperationCanceledPacket {
            try connectionLayer.acknowledgeOperationCanceled()
            state = .inactive
            return
        }

        switch state {
        case .inactive:
            break
        case .requestedSync:
            try handleInRequestedSync(packet: packet)
        case .requestedSyncOptions:
            try handleInRequestedSyncOptions(packet: packet)
        case let .setStore(storesProgress):
            try handleInSetStore(packet: packet,
                                 storesProgress: storesProgress)
        case let .setSoup(soupsProgress):
            try handleInSetSoup(packet: packet,
                                soupsProgress: soupsProgress)
        case let .requestedSoupIDs(soupsProgress):
            try handleInRequestedSoupIDs(packet: packet,
                                         soupsProgress: soupsProgress)
        case let .requestedEntry(soupProgress):
            try handleInRequestedEntry(packet: packet,
                                       soupProgress: soupProgress)
        }
    }

    private func handleInRequestedSync(packet: DecodableDockPacket) throws {
        guard
            let resultPacket = packet as? ResultPacket,
            resultPacket.error == .ok
        else {
            try sendError()
            return
        }

        try handleRequest()
    }

    private func handleInRequestedSyncOptions(packet: DecodableDockPacket) throws {
        guard let syncOptionsPacket = packet as? SyncOptionsPacket else {
            try sendError()
            return
        }

        let stores: [NewtonFrame]
        do {
            stores = try decodeStores(syncOptionsPacket: syncOptionsPacket)
        } catch Error.invalidSyncOptions {
            try sendError()
            return
        }

        guard let store = stores.first else {
            try stop()
            return
        }

        do {
            let progress =
                StoresProgress(current: store,
                               remaining: Array(stores.dropFirst()))
            try setStore(progress: progress)
        } catch Error.invalidStoreFrame {
            try sendError()
        }
    }

    private func handleInSetStore(packet: DecodableDockPacket,
                                  storesProgress: StoresProgress) throws {

        guard let soupNamesPacket = packet as? SoupNamesPacket else {
            try sendError()
            return
        }

        // ensure we got signatures for all soups
        let count = soupNamesPacket.names.values.count
        guard soupNamesPacket.signatures.values.count == count else {
            try sendError()
            return
        }

        let names = soupNamesPacket.names.values.flatMap {
            ($0 as? NewtonString)?.string
        }

        let signatures = soupNamesPacket.signatures.values.flatMap {
            ($0 as? NewtonInteger)?.integer
        }

        guard names.count == count && signatures.count == count else {
            try sendError()
            return
        }

        let supportedNames = names.filter {
            DockBackupLayer.supportedSoups.contains($0)
        }

        let soups = zip(supportedNames, signatures).map {
            SoupInfo(name: $0.0, signature: $0.1)
        }

        guard let soup = soups.first else {
            try requestNextStore(storesProgress: storesProgress)
            return
        }

        let soupsProgress =
            SoupsProgress(current: soup,
                          remaining: Array(soups.dropFirst()),
                          storesProgress: storesProgress)

        try setSoup(soupsProgress: soupsProgress)
    }

    private func isValidSetSoupResponse(packet: DecodableDockPacket) -> Bool {
        // sometime the Newton just answers with a ResultPacket
        // instead of a SoupInfoPacket. that's fine, but why?
        if case let resultPacket as ResultPacket = packet,
            resultPacket.error == .ok {

            return true
        }

        // TODO: is there any valuable information in here we should extract?
        return packet is SoupInfoPacket
    }

    private func handleInSetSoup(packet: DecodableDockPacket,
                                 soupsProgress: SoupsProgress) throws {

        guard isValidSetSoupResponse(packet: packet) else {
            try sendError()
            return
        }

        try requestSoupIDs(soupsProgress: soupsProgress)
    }

    private func handleInRequestedSoupIDs(packet: DecodableDockPacket,
                                          soupsProgress: SoupsProgress) throws {

        guard let soupIDsPacket = packet as? SoupIDsPacket else {
            try sendError()
            return
        }

        guard let entry = soupIDsPacket.ids.first else {
            try requestNextSoup(soupsProgress: soupsProgress)
            return
        }


        let soupProgress =
            SoupProgress(current: entry,
                         remaining: Array(soupIDsPacket.ids.dropFirst()),
                         soupsProgress: soupsProgress)

        try requestEntry(soupProgress: soupProgress)
    }

    private func handleInRequestedEntry(packet: DecodableDockPacket,
                                        soupProgress: SoupProgress) throws {

        guard let entryPacket = packet as? EntryPacket else {
            try sendError()
            return
        }

        // TODO:
        debugPrint(entryPacket.entry)

        try requestNextEntry(soupProgress: soupProgress)
    }

    private func decodeStores(syncOptionsPacket: SyncOptionsPacket) throws -> [NewtonFrame] {

        guard
            let syncOptions = syncOptionsPacket.syncOptions as? NewtonFrame,
            let storesArray = syncOptions["stores"] as? NewtonPlainArray
        else {
            throw Error.invalidSyncOptions
        }

        let stores = storesArray.values.flatMap { $0 as? NewtonFrame }
        guard stores.count == storesArray.values.count else {
            throw Error.invalidSyncOptions
        }

        return stores
    }

    private func setStore(progress: StoresProgress) throws {

        let store = progress.current

        guard
            let name = store["name"] as? NewtonString,
            let signature = store["signature"] as? NewtonInteger,
            let kind = store["kind"] as? NewtonString
        else {
            throw Error.invalidStoreFrame
        }

        try write(packet: SetStoreGetNamesPacket(storeFrame: [
            "name": name,
            "kind": kind,
            "signature": signature
        ]))

        state = .setStore(progress)
    }

    private func setSoup(soupsProgress: SoupsProgress) throws {

        let soup = soupsProgress.current

        try write(packet: SetSoupGetInfoPacket(name: soup.name))

        state = .setSoup(soupsProgress)
    }

    private func requestSoupIDs(soupsProgress: SoupsProgress) throws {
        try write(packet: GetSoupIDsPacket())

        state = .requestedSoupIDs(soupsProgress)
    }

    private func requestEntry(soupProgress: SoupProgress) throws {

        try write(packet: ReturnEntryPacket(id: soupProgress.current))

        state = .requestedEntry(soupProgress)
    }

    private func requestNextStore(storesProgress: StoresProgress) throws {
        guard let next = storesProgress.remaining.first else {
            try stop()
            return
        }

        do {
            let progress =
                StoresProgress(current: next,
                               remaining: Array(storesProgress.remaining.dropFirst()))
            try setStore(progress: progress)
        } catch Error.invalidStoreFrame {
            try sendError()
        }
    }

    private func requestNextSoup(soupsProgress: SoupsProgress) throws {

        guard let next = soupsProgress.remaining.first else {
            try requestNextStore(storesProgress: soupsProgress.storesProgress)
            return
        }

        let soupsProgress =
            SoupsProgress(current: next,
                          remaining: Array(soupsProgress.remaining.dropFirst()),
                          storesProgress: soupsProgress.storesProgress)
        try setSoup(soupsProgress: soupsProgress)
    }

    private func requestNextEntry(soupProgress: SoupProgress) throws {

        guard let next = soupProgress.remaining.first else {
            try requestNextSoup(soupsProgress: soupProgress.soupsProgress)
            return
        }

        let soupProgress =
            SoupProgress(current: next,
                         remaining: Array(soupProgress.remaining.dropFirst()),
                         soupsProgress: soupProgress.soupsProgress)
        try requestEntry(soupProgress: soupProgress)
    }

    public func stop() throws {
        if connectionLayer.state == .connected {
            return
        }

        guard connectionLayer.state == .backingUp else {
            throw Error.notActive
        }

        try connectionLayer.completeOperation()
        state = .inactive
    }
}
