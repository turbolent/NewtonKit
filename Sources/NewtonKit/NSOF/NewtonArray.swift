
import Foundation


public final class NewtonArray: NewtonObject {

    public enum DecodingError: Error {
        case missingLength
        case missingClass
        case invalidValue
    }

    public let `class`: NewtonObject
    public let values: [NewtonObject]

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonArray {

        // Number of slots (xlong)
        guard let length = decoder.decodeXLong() else {
            throw DecodingError.missingLength
        }

        // Class (object)
        guard let `class` = try decoder.decodeObject() else {
            throw DecodingError.missingClass
        }

        // Slot tags in ascending order (symbol objects)
        let values: [NewtonObject] = try (0..<Int(length)).map { _ in
            guard let value = try decoder.decodeObject() else {
                throw DecodingError.invalidValue
            }
            return value
        }

        return NewtonArray(class: `class`, values: values)
    }

    public init(class: NewtonObject, values: [NewtonObject]) {
        self.`class` = `class`
        self.values = values
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.array.rawValue])
        data.append(NewtonObjectEncoder.encode(xlong: Int32(values.count)))
        data.append(encoder.encode(newtonObject: `class`))
        for value in values {
            data.append(encoder.encode(newtonObject: value))
        }
        return data
    }
}
