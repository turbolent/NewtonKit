
import Foundation


public struct ResultPacket: CodableDockPacket, Equatable {

    public static let command: DockCommand = .result

    public enum DecodingError: Error {
        case invalidErrorCode
    }

    public let error: DockError

    public init(error: DockError) {
        self.error = error
    }

    public init(data: Data) throws {

        guard let errorCode = Int32(bigEndianData: data) else {
            throw DecodingError.invalidErrorCode
        }

        guard let error = DockError(rawValue: errorCode) else {
            throw DecodingError.invalidErrorCode
        }

        self.init(error: error)
    }

    public func encode() -> Data? {
        return error.rawValue.bigEndianData
    }

    public static func ==(lhs: ResultPacket, rhs: ResultPacket) -> Bool {
        return lhs.error == rhs.error
    }
}
