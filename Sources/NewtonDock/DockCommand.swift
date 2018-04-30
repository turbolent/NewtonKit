
public enum DockCommand: String {

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
    case operationCanceledAcknowledgement = "ocaa"

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
