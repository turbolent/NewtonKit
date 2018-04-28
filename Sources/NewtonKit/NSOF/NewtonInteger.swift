
import Foundation


public final class NewtonInteger: NewtonObject {

    public enum DecodingError: Error {
        case missingValue
        case notAnInteger
    }

    public let integer: Int32

    public static func isInteger(immediate: Int32) -> Bool {
        return immediate & 0x3 == 0
    }

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonInteger {

        guard let immediate = decoder.decodeXLong() else {
            throw DecodingError.missingValue
        }

        guard isInteger(immediate: immediate) else {
            throw DecodingError.notAnInteger
        }

        let integer = immediate >> 2

        return NewtonInteger(integer: integer)
    }

    public init(integer: Int32) {
        self.integer = integer
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.immediate.rawValue])
        data.append(NewtonObjectEncoder.encode(xlong: integer << 2))
        return data
    }
}


extension NewtonInteger: ExpressibleByIntegerLiteral {

    public convenience init(integerLiteral: Int32) {
        self.init(integer: integerLiteral)
    }
}


extension NewtonInteger: CustomStringConvertible {

    public var description: String {
        return String(describing: integer)
    }
}
