
import Foundation


public final class NewtonString: NewtonObject {

    public enum DecodingError: Error {
        case missingLength
        case missingString
        case invalidString
    }

    public let string: String

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonString {

        // Number of characters in name (xlong)
        guard let lengthValue = decoder.decodeXLong()  else {
            throw DecodingError.missingLength
        }

        let length = Int(lengthValue)

        // NOTE: -2 because 0 terminated, and half-words are used
        guard let stringData = decoder.decodeData(n: length - 2) else {
            throw DecodingError.missingString
        }

        guard let _ = decoder.decodeData(n: 2) else {
            throw DecodingError.missingString
        }

        guard let string = String(data: stringData, encoding: .utf16BigEndian) else {
            throw DecodingError.invalidString
        }

        return NewtonString(string: string)
    }

    public init(string: String) {
        self.string = string
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.string.rawValue])
        var stringData = string.data(using: .utf16BigEndian)!
        stringData.append(contentsOf: [0, 0])
        data.append(NewtonObjectEncoder.encode(xlong: Int32(stringData.count)))
        data.append(stringData)
        return data
    }
}


extension NewtonString: ExpressibleByStringLiteral {

    public convenience init(stringLiteral: String) {
        self.init(string: stringLiteral)
    }
}
