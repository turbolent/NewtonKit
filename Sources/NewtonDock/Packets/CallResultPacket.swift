
import Foundation
import NSOF


public struct CallResultPacket: DecodableDockPacket {

    public static let command: DockCommand = .callResult

    public enum DecodingError: Error {
        case missingResult
    }

    public let result: NewtonObject

    public init(data: Data) throws {
        guard case (let result?, _) =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            throw DecodingError.missingResult
        }
        self.result = result
    }
}
