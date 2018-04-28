
import Foundation


public struct NewtonUnicodeCharacter: NewtonObject {

    public enum DecodingError: Error {
        case missingCharacter
    }

    public let character: UInt16

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonUnicodeCharacter {

        guard let character = decoder.decodeUInt16() else {
            throw DecodingError.missingCharacter
        }

        return NewtonUnicodeCharacter(character: character)
    }

    public init(character: UInt16) {
        self.character = character
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.unicodeCharacter.rawValue])
        data.append(character.bigEndianData)
        return data
    }
}


extension NewtonUnicodeCharacter: CustomStringConvertible {

    public var description: String {
        return String(format: "$\\u%4x", character)
    }
}
