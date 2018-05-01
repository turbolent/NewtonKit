
import Foundation


public struct NewtonCharacter: NewtonObject {

    public enum DecodingError: Error {
        case missingCharacter
        case missingImmediate
        case notAnImmediateCharacter
    }

    public static func isCharacter(immediate: Int32) -> Bool {
        return (immediate & 0xF) == 6
    }

    public let character: UInt8

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonCharacter {

        guard let character = decoder.decodeByte() else {
            throw DecodingError.missingCharacter
        }

        return NewtonCharacter(character: character)
    }

    public static func decodeImmediate(decoder: NewtonObjectDecoder) throws -> NewtonCharacter {

        guard let immediate = decoder.decodeXLong() else {
            throw DecodingError.missingImmediate
        }

        guard isCharacter(immediate: immediate) else {
            throw DecodingError.notAnImmediateCharacter
        }

        // TODO: or are immediate characters UInt16, i.e. NewtonUnicodeCharacter?
        let character = UInt8((immediate >> 4) & 0xFFFF)

        return NewtonCharacter(character: character)
    }

    public init(character: UInt8) {
        self.character = character
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        return Data(bytes: [
            NewtonObjectType.character.rawValue,
            character
        ])
    }
}


extension NewtonCharacter: CustomStringConvertible {

    public var description: String {
        return String(format: "$\\%2x", character)
    }
}


extension NewtonCharacter: Equatable {

    public static func ==(lhs: NewtonCharacter, rhs: NewtonCharacter) -> Bool {
        return lhs.character == rhs.character
    }
}
