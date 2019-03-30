
import Foundation


public protocol NewtonObject {

    func encode(encoder: NewtonObjectEncoder) -> Data
    static func decode(decoder: NewtonObjectDecoder) throws -> Self
}

public extension NewtonObject {

    public var integerValue: Int32? {
        return (self as? NewtonInteger)?.integer
    }

    public var stringValue: String? {
        return (self as? NewtonString)?.string
    }

    public var doubleValue: Double? {
        return (self as? NewtonBinary)?.doubleValue
    }

    public var symbolName: String? {
        return (self as? NewtonSymbol)?.name
    }
}
