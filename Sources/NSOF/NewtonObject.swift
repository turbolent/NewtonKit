
import Foundation


public protocol NewtonObject {

    func encode(encoder: NewtonObjectEncoder) -> Data
    static func decode(decoder: NewtonObjectDecoder) throws -> Self
}

public extension NewtonObject {

    var integerValue: Int32? {
        return (self as? NewtonInteger)?.integer
    }

    var stringValue: String? {
        return (self as? NewtonString)?.string
    }

    var doubleValue: Double? {
        return (self as? NewtonBinary)?.doubleValue
    }

    var symbolName: String? {
        return (self as? NewtonSymbol)?.name
    }
}
