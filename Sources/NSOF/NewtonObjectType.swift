
import Foundation


public enum NewtonObjectType: UInt8 {
    case immediate
    case character
    case unicodeCharacter
    case binary
    case array
    case plainArray
    case frame
    case symbol
    case string
    case precedent
    case `nil`
    case smallRect

    var swiftType: NewtonObject.Type? {
        switch self {
        case .character:
            return NewtonCharacter.self
        case .unicodeCharacter:
            return NewtonUnicodeCharacter.self
        case .binary:
            return NewtonBinary.self
        case .array:
            return NewtonArray.self
        case .plainArray:
            return NewtonPlainArray.self
        case .frame:
            return NewtonFrame.self
        case .symbol:
            return NewtonSymbol.self
        case .string:
            return NewtonString.self
        case .smallRect:
            return NewtonSmallRect.self
        default:
            return nil
        }
    }

    public static let precedentTypes: Set<NewtonObjectType> =
        [.binary, .array, .plainArray, .frame, .symbol, .string, .smallRect]
}
