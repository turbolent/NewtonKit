
import Foundation


public struct ResultPacket: CodableDockPacket, Equatable {

    public static let command: DockCommand = .result

    public enum DecodingError: Error {
        case invalidErrorCode
    }

    public let errorCode: Int32

    public init(errorCode: Int32) {
        self.errorCode = errorCode
    }

    public init(data: Data) throws {

        guard let errorCode = Int32(bigEndianData: data) else {
            throw DecodingError.invalidErrorCode
        }

        self.init(errorCode: errorCode)
    }

    public func encode() -> Data? {
        return errorCode.bigEndianData
    }

    public static func ==(lhs: ResultPacket, rhs: ResultPacket) -> Bool {
        return lhs.errorCode == rhs.errorCode
    }
}
