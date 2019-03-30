
import Foundation


public final class NewtonPlainArray: NewtonObject {

    public enum DecodingError: Error {
        case missingLength
        case invalidValue
    }

    /// Slot values in ascending order (objects)
    public let values: [NewtonObject]

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonPlainArray {

        // Number of slots (xlong)
        guard let length = decoder.decodeXLong() else {
            throw DecodingError.missingLength
        }

        // Slot values in ascending order (objects)
        let values: [NewtonObject] = try (0..<Int(length)).map { _ in
            guard let value = try decoder.decodeObject() else {
                throw DecodingError.invalidValue
            }
            return value
        }

        return NewtonPlainArray(values: values)
    }

    public init(values: [NewtonObject]) {
        self.values = values
    }

    public subscript(index: Int) -> NewtonObject? {
        get {
            return values[index]
        }
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data([NewtonObjectType.plainArray.rawValue])
        data.append(NewtonObjectEncoder.encode(xlong: Int32(values.count)))
        for value in values {
            data.append(encoder.encode(newtonObject: value))
        }
        return data
    }
}


extension NewtonPlainArray: ExpressibleByArrayLiteral {

    public convenience init(arrayLiteral elements: NewtonObject...) {
        self.init(values: elements)
    }
}


extension NewtonPlainArray: CustomStringConvertible {

    public var description: String {
        let contents = values
            .map { String(describing: $0) }
            .joined(separator: ", ")
        return "[ \(contents) ]"
    }
}
