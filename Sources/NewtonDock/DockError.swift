public struct DockError: RawRepresentable {

    private static let base1: Int32 = -28000
    private static let base2: Int32 = base1 - 100

    public static let ok = DockError(0)

    public static let badStoreSignature = DockError(base1 -  1)
    public static let badEntry = DockError(base1 -  2)
    public static let aborted = DockError(base1 -  3)
    public static let badQuery = DockError(base1 -  4)
    public static let readEntryError = DockError(base1 -  5)
    public static let badCurrentSoup = DockError(base1 -  6)
    public static let badCommandLength = DockError(base1 -  7)
    public static let entryNotFound = DockError(base1 -  8)
    public static let badConnection = DockError(base1 -  9)
    public static let fileNotFound = DockError(base1 - 10)
    public static let incompatibleProtocol = DockError(base1 - 11)
    public static let protocolError = DockError(base1 - 12)
    public static let dockingCanceled = DockError(base1 - 13)
    public static let storeNotFound = DockError(base1 - 14)
    public static let soupNotFound = DockError(base1 - 15)
    public static let badHeader = DockError(base1 - 16)
    public static let outOfMemory = DockError(base1 - 17)
    public static let newtonVersionTooNew = DockError(base1 - 18)
    public static let packageCantLoad = DockError(base1 - 19)
    public static let protocolExtAlreadyRegistered = DockError(base1 - 20)
    public static let remoteImportError = DockError(base1 - 21)
    public static let badPasswordError = DockError(base1 - 22)
    public static let retryPW = DockError(base1 - 23)
    public static let idleTooLong = DockError(base1 - 24)
    public static let outOfPower = DockError(base1 - 25)
    public static let badCursor = DockError(base1 - 26)
    public static let alreadyBusy = DockError(base1 - 27)
    public static let desktopError = DockError(base1 - 28)
    public static let cantConnectToModem = DockError(base1 - 29)
    public static let disconnected = DockError(base1 - 30)
    public static let accessDenied = DockError(base1 - 31)

    public static let disconnectDuringRead = DockError(base2)
    public static let readFailed = DockError(base2 -  1)
    public static let communicationsToolNotFound = DockError(base2 -  2)
    public static let invalidModemToolVersion = DockError(base2 -  3)
    public static let cardNotInstalled = DockError(base2 -  4)
    public static let browserFileNotFound = DockError(base2 -  5)
    public static let browserVolumeNotFound = DockError(base2 -  6)
    public static let browserPathNotFound = DockError(base2 -  7)

    public let rawValue: Int32

    private init(_ rawValue: Int32) {
        self.rawValue = rawValue
    }

    public init?(rawValue: Int32) {
        switch rawValue {
        case DockError.ok.rawValue:
            self = .ok

        case DockError.badStoreSignature.rawValue:
            self = .badStoreSignature
        case DockError.badEntry.rawValue:
            self = .badEntry
        case DockError.aborted.rawValue:
            self = .aborted
        case DockError.badQuery.rawValue:
            self = .badQuery
        case DockError.readEntryError.rawValue:
            self = .readEntryError
        case DockError.badCurrentSoup.rawValue:
            self = .badCurrentSoup
        case DockError.badCommandLength.rawValue:
            self = .badCommandLength
        case DockError.entryNotFound.rawValue:
            self = .entryNotFound
        case DockError.badConnection.rawValue:
            self = .badConnection
        case DockError.fileNotFound.rawValue:
            self = .fileNotFound
        case DockError.incompatibleProtocol.rawValue:
            self = .incompatibleProtocol
        case DockError.protocolError.rawValue:
            self = .protocolError
        case DockError.dockingCanceled.rawValue:
            self = .dockingCanceled
        case DockError.storeNotFound.rawValue:
            self = .storeNotFound
        case DockError.soupNotFound.rawValue:
            self = .soupNotFound
        case DockError.badHeader.rawValue:
            self = .badHeader
        case DockError.outOfMemory.rawValue:
            self = .outOfMemory
        case DockError.newtonVersionTooNew.rawValue:
            self = .newtonVersionTooNew
        case DockError.packageCantLoad.rawValue:
            self = .packageCantLoad
        case DockError.protocolExtAlreadyRegistered.rawValue:
            self = .protocolExtAlreadyRegistered
        case DockError.remoteImportError.rawValue:
            self = .remoteImportError
        case DockError.badPasswordError.rawValue:
            self = .badPasswordError
        case DockError.retryPW.rawValue:
            self = .retryPW
        case DockError.idleTooLong.rawValue:
            self = .idleTooLong
        case DockError.outOfPower.rawValue:
            self = .outOfPower
        case DockError.badCursor.rawValue:
            self = .badCursor
        case DockError.alreadyBusy.rawValue:
            self = .alreadyBusy
        case DockError.desktopError.rawValue:
            self = .desktopError
        case DockError.cantConnectToModem.rawValue:
            self = .cantConnectToModem
        case DockError.disconnected.rawValue:
            self = .disconnected
        case DockError.accessDenied.rawValue:
            self = .accessDenied

        case DockError.disconnectDuringRead.rawValue:
            self = .disconnectDuringRead
        case DockError.readFailed.rawValue:
            self = .readFailed
        case DockError.communicationsToolNotFound.rawValue:
            self = .communicationsToolNotFound
        case DockError.invalidModemToolVersion.rawValue:
            self = .invalidModemToolVersion
        case DockError.cardNotInstalled.rawValue:
            self = .cardNotInstalled
        case DockError.browserFileNotFound.rawValue:
            self = .browserFileNotFound
        case DockError.browserVolumeNotFound.rawValue:
            self = .browserVolumeNotFound
        case DockError.browserPathNotFound.rawValue:
            self = .browserPathNotFound

        default:
            return nil
        }
    }
}
