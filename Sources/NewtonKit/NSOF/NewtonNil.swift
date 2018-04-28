
import Foundation


public final class NewtonNil: NewtonObject {

    public static let `nil` = NewtonNil()

    private init() {}

    public static func isNil(immediate: Int32) -> Bool {
        return immediate == 2
    }

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonNil {
        return NewtonNil.`nil`
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        return Data(bytes: [NewtonObjectType.`nil`.rawValue])
    }
}
