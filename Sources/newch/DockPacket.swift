
import Foundation

// Newton 1.0 Connection Protocol / Dante Connection Protocol
//
// Documented by Newton Research http://newtonresearch.org/
//
// Newton communicates with the desktop by exchanging Newton event commands.
// The general command structure looks like this:
//
//   ULong 'newt'    // event header
//   ULong 'dock'    // event header
//   ULong 'aaaa'    // specific command
//   ULong length    // the length in bytes of the following data
//   UChar data[]    // data, if any
//
// NOTE
// • The length associated with each command is the actual length in bytes
//   of the data following the length field.
// • Data is padded with nulls to a 4 byte boundary.
// • Multi-byte values are in big-endian order.
// • Strings are null-terminated 2-byte UniChar strings unless otherwise specified.

public struct DockPacket {

    public enum DecodingError: Error {
        case invalidSize
        case invalidHeader
        case invalidCommand
        case invalidLength
    }


    private static let header = "newtdock".data(using: .ascii)!
    private static let boundary = 4

    public let command: Command
    public let data: Data

    public init(command: Command, data: Data) {
        self.command = command
        self.data = data
    }

    public init(data: Data) throws {

        // check size
        guard data.count >= 16 else {
            throw DecodingError.invalidSize
        }

        // check header
        let headerStartIndex = data.startIndex
        let headerEndIndex = headerStartIndex.advanced(by: 2 * DockPacket.boundary)
        let header = data.subdata(in: headerStartIndex..<headerEndIndex)
        guard header == DockPacket.header else {
            throw DecodingError.invalidHeader
        }

        // decode command
        let commandStartIndex = headerEndIndex
        let commandEndIndex = commandStartIndex.advanced(by: DockPacket.boundary)
        let commandData = data.subdata(in: commandStartIndex..<commandEndIndex)
        guard
            let commandString = String(data: commandData, encoding: .ascii),
            let command = Command(rawValue: commandString)
        else {
            throw DecodingError.invalidCommand
        }
        self.command = command

        // decode data length
        let lengthStartIndex = commandEndIndex
        let lengthEndIndex = lengthStartIndex.advanced(by: DockPacket.boundary)
        let lengthData = data.subdata(in: lengthStartIndex..<lengthEndIndex)
        guard let length = UInt32(bigEndianData: lengthData) else {
            throw DecodingError.invalidLength
        }

        // decode data
        let dataStartIndex = lengthEndIndex
        let dataEndIndex = dataStartIndex.advanced(by: Int(length))
        self.data = data.subdata(in: dataStartIndex..<dataEndIndex)
    }

    public enum Command: String {

        // Starting a Session
        // Newton -> Desktop
        case requestToAutoDock = "auto"
        case requestToDock = "rtdk"
        case newtonName = "name"  // + NewtonInfo + UniChar[] name
        case newtonInfo = "ninf"  // + protocol version + encrypted key
        case password = "pass"  // + encrypted key

        // Desktop -> Newton
        case initiateDocking = "dock"
        case setTimeout = "stim"  // + timeout in seconds
        case whichIcons = "wicn"  // + bit mask
        case desktopInfo = "dinf"  // + desktop info
        case pWWrong = "pwbd"

        // Desktop <- -> Newton
        case result = "dres"  // + error code
        case disconnect = "disc"
        case hello = "helo"
        case test = "test"
        case refTest = "rtst"
        case unknownCommand = "unkn"

        // Desktop -> Newton
        case lastSyncTime = "stme"  // + time in minutes
        case getStoreNames = "gsto"  // + array ref of store info
        case getSoupNames = "gets"
        case setCurrentStore = "ssto"
        case setCurrentSoup = "ssou"
        case getSoupIDs = "gids"
        case getChangedIDs = "gcid"
        case deleteEntries = "dele"
        case addEntry = "adde"
        case changedEntry = "cent"
        case returnEntry = "rete"
        case returnChangedEntry = "rcen"
        case emptySoup = "esou"
        case deleteSoup = "dsou"
        case getIndexDescription = "gind"
        case createSoup = "csop"
        case getSoupInfo = "gsin"

        // Newton 1 protocol
        case getPackageIDs = "gpid"
        case backupPackages = "bpkg"
        case deleteAllPackages = "dpkg"
        case deletePkgDir = "dpkd"
        case getInheritance = "ginh"
        case getPatches = "gpat"
        case restorePatch = "rpat"

        // Newton -> Desktop
        case currentTime = "time"
        case storeNames = "stor"
        case soupNames = "soup"
        case soupIDs = "sids"
        case soupInfo = "sinf"
        case indexDescription = "indx"
        case changedIDs = "cids"
        case addedID = "adid"
        case entry = "entr"

        // Newton 1 protocol
        case packageIdList = "pids"
        case package = "apkg"
        case inheritance = "dinh"
        case patches = "patc"

        // Load Package
        // Newton -> Desktop
        case loadPackageFile = "lpfl"
        // Desktop -> Newton
        case loadPackage = "lpkg"

        // Remote Query
        // Desktop -> Newton
        case query = "qury"
        case cursorGotoKey = "goto"
        case cursorMap = "cmap"
        case cursorEntry = "crsr"
        case cursorMove = "move"
        case cursorNext = "next"
        case cursorPrev = "prev"
        case cursorReset = "rset"
        case cursorResetToEnd = "rend"
        case cursorWhichEnd = "whch"
        case cursorCountEntries = "cnt"
        case cursorFree = "cfre"
        // Newton -> Desktop
        case longData = "ldta"
        case refResult = "ref"

        // Keyboard Passthrough
        // Desktop <- -> Newton
        case startKeyboardPassthrough = "kybd"
        // Desktop -> Newton
        case keyboardChar = "kbdc"  // + UniChar + flags
        case keyboardString = "kbds"  // + UniChar[]

        // Misc additions
        // Newton -> Desktop
        case defaultStore = "dfst"
        case appNames = "appn"
        case importParameterSlipResult = "islr"
        case packageInfo = "pinf"
        case setBaseID = "base"
        case backupIDs = "bids"
        case backupSoupDone = "bsdn"
        case soupNotDirty = "ndir"
        case synchronize = "sync"
        case callResult = "cres"

        // Desktop -> Newton
        case removePackage = "rmvp"
        case resultString = "ress"
        case sourceVersion = "sver"
        case addEntryWithUniqueID = "auni"
        case getPackageInfo = "gpin"
        case getDefaultStore = "gdfs"
        case createDefaultSoup = "cdsp"
        case getAppNames = "gapp"
        case regProtocolExtension = "pext"
        case removeProtocolExtension = "rpex"
        case setStoreSignature = "ssig"
        case setSoupSignature = "ssos"
        case importParametersSlip = "islp"
        case getPassword = "gpwd"
        case sendSoup = "snds"
        case backupSoup = "bksp"
        case setStoreName = "ssna"
        case callGlobalFunction = "cgfn"
        case callRootMethod = "crmf"  // spec says 'crmd'!
        case setVBOCompression = "cvbo"

        // Desktop <- -> Newton
        case operationDone = "opdn"
        case operationCanceled = "opca"  // spec says 'opcn'!
        case opCanceledAck = "ocaa"

        // Sync and Selective Sync
        // Newton -> Desktop
        case requestToSync = "ssyn"
        case syncOptions = "sopt"

        // Desktop -> Newton
        case getSyncOptions = "gsyn"
        case syncResults = "sres"
        case setStoreGetNames = "ssgn"
        case setSoupGetInfo = "ssgi"
        case getChangedIndex = "cidx"
        case getChangedInfo = "cinf"

        // File browsing
        // Newton -> Desktop
        case requestToBrowse = "rtbr"
        case getDevices = "gdev"  // Windows only
        case getDefaultPath = "dpth"
        case getFilesAndFolders = "gfil"
        case setPath = "spth"
        case getFileInfo = "gfin"
        case internalStore = "isto"
        case resolveAlias = "rali"
        case getFilters = "gflt"  // Windows only
        case setFilter = "sflt"  // Windows only
        case setDrive = "sdrv"  // Windows only

        // Desktop -> Newton
        case devices = "devs"  // Windows only
        case filters = "filt"  // Windows only
        case path = "path"
        case filesAndFolders = "file"
        case fileInfo = "finf"
        case getInternalStore = "gist"
        case aliasResolved = "alir"

        // File importing
        // Newton -> Desktop
        case importFile = "impt"
        case setTranslator = "tran"

        // Desktop -> Newton
        case translatorList = "trnl"
        case importing = "dimp"
        case soupsChanged = "schg"
        case setStoreToDefault = "sdef"

        // Restore originated on Newton
        // Newton -> Desktop
        case restoreFile = "rsfl"
        case getRestoreOptions = "grop"
        case restoreAll = "rall"

        // Desktop <- -> Newton
        case restoreOptions = "ropt"
        case restorePackage = "rpkg"

        // Desktop Initiated Functions while connected
        // Desktop  -> Newton
        case desktopInControl = "dsnc"
        //case requestToSync = "ssyn"
        case requestToRestore = "rrst"
        case requestToInstall = "rins"

        // Newton 2.1
        case setStatusText = "stxt"
    }

    public enum SessionType: UInt32 {
        case noSession
        case settingUpSession
        case synchronizeSession
        case restoreSession
        case loadPackageSession
        case testCommSession
        case loadPatchSession
        case updatingStoresSession
    }
}


extension DockPacket: Equatable {

    public static func == (lhs: DockPacket, rhs: DockPacket) -> Bool {
        return lhs.command == rhs.command
            && lhs.data == rhs.data
    }
}
