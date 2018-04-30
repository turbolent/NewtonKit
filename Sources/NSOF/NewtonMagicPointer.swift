
import Foundation


public struct NewtonMagicPointer: NewtonObject {

    public enum DecodingError: Error {
        case missingValue
        case notAMagicPointer
    }

    public let pointer: Int32

    public static func isMagicPointer(immediate: Int32) -> Bool {
        return immediate & 0x3 == 3
    }

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonMagicPointer {

        guard let immediate = decoder.decodeXLong() else {
            throw DecodingError.missingValue
        }

        guard isMagicPointer(immediate: immediate) else {
            throw DecodingError.notAMagicPointer
        }

        let pointer = immediate >> 2

        return NewtonMagicPointer(pointer: pointer)
    }

    public init(pointer: Int32) {
        self.pointer = pointer
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.immediate.rawValue])
        data.append(NewtonObjectEncoder.encode(xlong: (pointer << 2) | 3))
        return data
    }
}


extension NewtonMagicPointer: CustomStringConvertible {

    public var description: String {
        return "*\(String(describing: pointer))"
    }
}
