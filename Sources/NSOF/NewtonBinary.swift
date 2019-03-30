
import Foundation


public final class NewtonBinary: NewtonObject {

    public enum DecodingError: Error {
        case missingLength
        case missingClass
        case missingData
    }

    /// Class (object)
    public let `class`: NewtonObject

    /// Data
    public let data: Data

    public static func decode(decoder: NewtonObjectDecoder)
        throws -> NewtonBinary {

        // Number of bytes of data (xlong)
        guard let lengthValue = decoder.decodeXLong() else {
            throw DecodingError.missingLength
        }

        let length = Int(lengthValue)

        // Class (object)
        guard let `class` = try decoder.decodeObject() else {
            throw DecodingError.missingClass
        }

        // Data
        guard let binaryData = decoder.decodeData(n: length) else {
            throw DecodingError.missingData
        }

        return NewtonBinary(class: `class`, data: binaryData)
    }

    public init(`class`: NewtonObject, data: Data) {
        self.`class` = `class`
        self.data = data
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data([NewtonObjectType.binary.rawValue])
        data.append(NewtonObjectEncoder.encode(xlong: Int32(self.data.count)))
        data.append(encoder.encode(newtonObject: `class`))
        data.append(self.data)
        return data
    }

    public var doubleValue: Double? {
        guard
            let classSymbol = `class` as? NewtonSymbol,
            classSymbol.name.caseInsensitiveCompare("real") == .orderedSame
        else {
            return nil
        }
        return Double(bitPattern: UInt64(bigEndian: data.withUnsafeBytes { $0.pointee } ))
    }
}


extension NewtonBinary: CustomStringConvertible {

    public var description: String {
        return "<\(String(describing: `class`)), length \(data.count)>"
    }
}

