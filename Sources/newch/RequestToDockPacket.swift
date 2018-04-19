
import Foundation


public struct RequestToDockPacket: CodableDockPacket, Equatable {

    public static let command: DockCommand = .requestToDock

    public enum DecodingError: Error {
        case invalidProtocolVersion
    }

    public let protocolVersion: UInt32

    public init(protocolVersion: UInt32) {
        self.protocolVersion = protocolVersion
    }

    public init(data: Data) throws {

        guard let protocolVersion = UInt32(bigEndianData: data) else {
            throw DecodingError.invalidProtocolVersion
        }

        self.init(protocolVersion: protocolVersion)
    }

    public func encode() -> Data? {
        return protocolVersion.bigEndianData
    }

    public static func ==(lhs: RequestToDockPacket, rhs: RequestToDockPacket) -> Bool {
        return lhs.protocolVersion == rhs.protocolVersion
    }
}
