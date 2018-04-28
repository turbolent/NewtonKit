
import Foundation


public struct NewtonTrue: NewtonObject {

    public enum DecodingError: Error {
        case missingValue
        case notTrue
    }

    public static let `true` = NewtonTrue()

    private init() {}

    public static func isTrue(immediate: Int32) -> Bool {
        return immediate == 0x1A
    }

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonTrue {

        guard let immediate = decoder.decodeXLong() else {
            throw DecodingError.missingValue
        }

        guard isTrue(immediate: immediate) else {
            throw DecodingError.notTrue
        }

        return NewtonTrue.`true`
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        return Data(bytes: [
            NewtonObjectType.immediate.rawValue,
            0x1A
        ])
    }
}

