
import Foundation

public final class DockConnectionLayer {

    public enum State {
        case idle
        case initiatedDocking
        case sentDesktopInfo
        case sentWhichIcons
        case sentSetTimeout
        case connected
        case sentKeyboardPassthrough
        case keyboardPassthrough
        case initiatedSync
        case disconnected
    }

    public enum Error: Swift.Error {
        case sendingWhichIconsFailed
        case missingNewtonKey
        case newtonKeyEnryptionKeyFailed
        case notConnected
        case notInKeyboardPassthrough
    }

    private static let timeout: UInt32 = 60

    private static let desktopKey =
        Data(bytes: [0x64, 0x23, 0xef, 0x02, 0xfb, 0xcd, 0xc5, 0xa5])

    private static let desktopApps: NewtonPlainArray =
        [
            ["id": 2 as NewtonInteger,
             "name": "Newton Connection Utilities" as NewtonString,
             "version": 1 as NewtonInteger]
            as NewtonFrame
        ]

    private static let desKey: [UInt8] =
        [0xe4, 0x0f, 0x7e, 0x9f, 0x0a, 0x36, 0x2c, 0xfa]

    public var onStateChange: ((State, State) -> Void)?
    public var onDisconnect: (() -> Void)?
    public var onWrite: ((EncodableDockPacket) throws -> Void)?

    public private(set) var state: State = .idle {
        didSet {
            onStateChange?(oldValue, state)
        }
    }

    private var des: DES
    private var newtonKey: Data?

    private var syncOptions: NewtonFrame?

    public init() throws {
        des = try DES(keyBytes: DockConnectionLayer.desKey)
    }

    public func read(packet: DecodableDockPacket) throws {

        print("XXX \(packet)")

        if packet is DisconnectPacket {
            state = .disconnected
            onDisconnect?()
            return
        }

        switch state {
        case .idle:
            if packet is RequestToDockPacket {
                try write(packet: InitiateDockingPacket(sessionType: .noSession))
                state = .initiatedDocking
            }
        case .initiatedDocking:
            if packet is NewtonNamePacket {
                let packet =
                    try DesktopInfoPacket(protocolVersion: 10,
                                          desktopType: .macintosh,
                                          encryptedKey: DockConnectionLayer.desktopKey,
                                          sessionType: .settingUpSession,
                                          allowSelectiveSync: false,
                                          desktopApps: DockConnectionLayer.desktopApps)
                try write(packet: packet)
                state = .sentDesktopInfo
            }
        case .sentDesktopInfo:
            if let newtonInfoPacket = packet as? NewtonInfoPacket {
                newtonKey = newtonInfoPacket.encryptedKey
                try write(packet: WhichIconsPacket(iconMask: .all))
                state = .sentWhichIcons
            }
        case .sentWhichIcons:
            if let resultPacket = packet as? ResultPacket {
                guard resultPacket.errorCode == 0 else {
                    throw Error.sendingWhichIconsFailed
                }
                try write(packet: SetTimeoutPacket(timeout: DockConnectionLayer.timeout))
                state = .sentSetTimeout
            }
        case .sentSetTimeout:
            if packet is PasswordPacket {
                guard let newtonKey = newtonKey else {
                    throw Error.missingNewtonKey
                }
                guard let encryptedKey = des.encrypt(source: newtonKey) else {
                    throw Error.newtonKeyEnryptionKeyFailed
                }
                try write(packet: PasswordPacket(encryptedKey: encryptedKey))
                state = .connected
            }
        case .connected:
            switch packet {
            case is OperationCanceledPacket:
                try write(packet: OperationCanceledAcknowledgementPacket())
                state = .connected
            case is StartKeyboardPassthroughPacket:
                try write(packet: StartKeyboardPassthroughPacket())
                state = .keyboardPassthrough
            case is RequestToSyncPacket:
                try write(packet: GetSyncOptionsPacket())
                state = .initiatedSync
            default:
                break
            }
        case .sentKeyboardPassthrough:
            if packet is StartKeyboardPassthroughPacket {
                state = .keyboardPassthrough
            }
        case .keyboardPassthrough:
            break
        case .initiatedSync:
            switch packet {
            case let syncOptionsPacket as SyncOptionsPacket:
                guard let syncOptions = syncOptionsPacket.syncOptions as? NewtonFrame else {
                    // TODO:
                    try write(packet: ResultPacket(errorCode: -28000 - 28))
                    break
                }
                self.syncOptions = syncOptions

                // request the time the current store was last backed up
                try write(packet: LastSyncTimePacket())
            case is CurrentTimePacket:
                guard
                    let syncOptions = syncOptions,
                    let stores = syncOptions["stores"] as? NewtonPlainArray,
                    let store = stores[0] as? NewtonFrame,
                    let name = store["name"] as? NewtonString,
                    let signature = store["signature"] as? NewtonInteger,
                    let kind = store["kind"] as? NewtonString
                else {
                    // TODO:
                    try write(packet: ResultPacket(errorCode: -28000 - 28))
                    break
                }

                try write(packet: SetStoreGetNamesPacket(storeFrame: [
                    "name": name,
                    "kind": kind,
                    "signature": signature
                ]))
            case is SoupNamesPacket:
                // TODO: all soups
                try write(packet: SetSoupGetInfoPacket(name: "Notes"))
            case is SoupInfoPacket:
                try write(packet: GetSoupIDsPacket())
            case let soupIDsPacket as SoupIDsPacket:
                try write(packet: ReturnEntryPacket(id: 0))
            case is EntryPacket:
                try write(packet: OperationDonePacket())
            case is OperationCanceledPacket:
                try write(packet: OperationCanceledAcknowledgementPacket())
                state = .connected
            default:
                break
            }
        case .disconnected:
            break
        }
    }

    private func write(packet: EncodableDockPacket) throws {
        try onWrite?(packet)
    }

    public func startDesktopControl() throws {
        try write(packet: DesktopInControlPacket())
    }

    public func startKeyboardPassthrough() throws {
        guard state == .connected else {
            throw Error.notConnected
        }

        try startDesktopControl()
        try write(packet: StartKeyboardPassthroughPacket())
        state = .sentKeyboardPassthrough
    }

    public func sendKeyboardCharacter(_ character: UInt16) throws {
        guard state == .keyboardPassthrough else {
            throw Error.notInKeyboardPassthrough
        }

        try write(packet: KeyboardCharPacket(character: character, state: 1))
    }

    public func sendKeyboardString(_ string: String) throws {
        guard state == .keyboardPassthrough else {
            throw Error.notInKeyboardPassthrough
        }

        try write(packet: KeyboardStringPacket(string: string))
    }

    public func stopKeyboardPassthrough() throws {
        if state == .connected {
            return
        }

        guard .keyboardPassthrough == state else {
            throw Error.notInKeyboardPassthrough
        }

        try stopDesktopControl()
        state = .connected
    }

    public func stopDesktopControl() throws {
        try write(packet: OperationDonePacket())
    }
}
