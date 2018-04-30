
import Foundation
import NSOF


public struct SoupNamesPacket: DecodableDockPacket {

    public static let command: DockCommand = .soupNames

    public enum DecodingError: Error {
        case missingOrInvalidNames
        case missingOrInvalidSignatures
    }

    public let names: NewtonPlainArray
    public let signatures: NewtonPlainArray

    public init(data: Data) throws {
        guard case let (names as NewtonPlainArray, namesLength) =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            throw DecodingError.missingOrInvalidNames
        }
        self.names = names

        guard case let (signatures as NewtonPlainArray, _) =
            try NewtonObjectDecoder.decodeRoot(data: data.dropFirst(namesLength))
        else {
            throw DecodingError.missingOrInvalidNames
        }
        self.signatures = signatures
    }
}

