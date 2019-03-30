
import Foundation


public struct NewtonNil: NewtonObject {

    public static let `nil` = NewtonNil()

    private init() {}

    public static func isNil(immediate: Int32) -> Bool {
        return immediate == 2
    }

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonNil {
        return NewtonNil.nil
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        return Data([NewtonObjectType.nil.rawValue])
    }
}


extension NewtonNil: ExpressibleByNilLiteral {

    public init(nilLiteral: ()) {
        self = NewtonNil.`nil`
    }
}


extension NewtonNil: CustomStringConvertible {

    public var description: String {
        return "nil"
    }
}
