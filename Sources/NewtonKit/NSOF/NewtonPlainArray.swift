
import Foundation


public final class NewtonPlainArray: NewtonObject {

    public enum DecodingError: Error {
        case missingLength
        case invalidValue
    }

    public let values: [NewtonObject]

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonPlainArray {

        // Number of slots (xlong)
        guard let length = decoder.decodeXLong() else {
            throw DecodingError.missingLength
        }

        // Slot tags in ascending order (symbol objects)
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

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.plainArray.rawValue])
        data.append(NewtonObjectEncoder.encode(xlong: Int32(values.count)))
        for value in values {
            data.append(encoder.encode(newtonObject: value))
        }
        return data
    }
}
