
import Foundation


public final class NewtonSmallRect: NewtonObject {

    public enum DecodingError: Error {
        case missingTop
        case missingLeft
        case missingBottom
        case missingRight
    }

    public let top: UInt8
    public let left: UInt8
    public let bottom: UInt8
    public let right: UInt8

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonSmallRect {

        guard let top = decoder.decodeByte() else {
            throw DecodingError.missingTop
        }

        guard let left = decoder.decodeByte() else {
            throw DecodingError.missingLeft
        }

        guard let bottom = decoder.decodeByte() else {
            throw DecodingError.missingBottom
        }

        guard let right = decoder.decodeByte() else {
            throw DecodingError.missingRight
        }

        return NewtonSmallRect(top: top,
                               left: left,
                               bottom: bottom,
                               right: right)
    }

    public init(top: UInt8, left: UInt8, bottom: UInt8, right: UInt8) {
        self.top = top
        self.left = left
        self.bottom = bottom
        self.right = right
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        return Data(bytes: [
            NewtonObjectType.smallRect.rawValue,
            top, left, bottom, right
        ])
    }
}


extension NewtonSmallRect: CustomStringConvertible {

    public var description: String {
        return "{"
            + "top: \(String(describing: top)), "
            + "left: \(String(describing: left)), "
            + "bottom: \(String(describing: bottom)), "
            + "right: \(String(describing: right))}"
    }
}


extension NewtonSmallRect: Equatable {

    public static func ==(lhs: NewtonSmallRect, rhs: NewtonSmallRect) -> Bool {
        return lhs.top == rhs.top
            && lhs.left == rhs.left
            && lhs.bottom == rhs.bottom
            && lhs.right == rhs.right
    }
}
