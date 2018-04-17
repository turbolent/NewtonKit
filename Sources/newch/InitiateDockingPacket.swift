
import Foundation


public struct InitiateDockingPacket: DockPacket, Equatable {

    public static let command: DockCommand = .initiateDocking

    public enum DecodingError: Error {
        case invalidSessionTypeData
        case invalidSessionType
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

    public let sessionType: SessionType

    public init(sessionType: SessionType) {
        self.sessionType = sessionType
    }

    public func encode() -> Data? {
        return sessionType.rawValue.bigEndianData
    }

    public static func ==(lhs: InitiateDockingPacket, rhs: InitiateDockingPacket) -> Bool {
        return lhs.sessionType == rhs.sessionType
    }
}
