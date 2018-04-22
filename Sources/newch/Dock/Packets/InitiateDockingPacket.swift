
import Foundation


public struct InitiateDockingPacket: EncodableDockPacket, Equatable {

    public static let command: DockCommand = .initiateDocking

    public enum DecodingError: Error {
        case invalidSessionTypeData
        case invalidSessionType
    }

    public let sessionType: DockSessionType

    public init(sessionType: DockSessionType) {
        self.sessionType = sessionType
    }

    public func encode() -> Data? {
        return sessionType.rawValue.bigEndianData
    }

    public static func ==(lhs: InitiateDockingPacket, rhs: InitiateDockingPacket) -> Bool {
        return lhs.sessionType == rhs.sessionType
    }
}
