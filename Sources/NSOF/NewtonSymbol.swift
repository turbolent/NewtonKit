
import Foundation


public final class NewtonSymbol: NewtonObject {

    public enum DecodingError: Error {
        case missingNameLength
        case missingName
        case invalidName
    }

    public let name: String

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonSymbol {

        // Number of characters in name (xlong)
        guard let nameLengthValue = decoder.decodeXLong() else {
            throw DecodingError.missingNameLength
        }

        let nameLength = Int(nameLengthValue)
       
        guard let nameData = decoder.decodeData(n: nameLength) else {
            throw DecodingError.missingName
        }

        guard let name = String(data: nameData, encoding: .ascii) else {
            throw DecodingError.invalidName
        }

        return NewtonSymbol(name: name)
    }

    public init(name: String) {
        self.name = name
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.symbol.rawValue])
        let nameData = name.data(using: .ascii)!
        data.append(NewtonObjectEncoder.encode(xlong: Int32(nameData.count)))
        data.append(nameData)
        return data
    }
}


extension NewtonSymbol: ExpressibleByStringLiteral {

    public convenience init(stringLiteral: String) {
        self.init(name: stringLiteral)
    }
}


extension NewtonSymbol: CustomStringConvertible {

    public var description: String {

        if name.unicodeScalars.first(where: { !CharacterSet.alphanumerics.contains($0) }) != nil {
            return String(format: "|%@|", name)
        }

        return name
    }
}


extension NewtonSymbol: Equatable {

    public static func ==(lhs: NewtonSymbol, rhs: NewtonSymbol) -> Bool {
        return lhs.name == rhs.name
    }
}
