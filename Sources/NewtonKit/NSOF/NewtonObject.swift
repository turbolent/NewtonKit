
import Foundation


public protocol NewtonObject {

    func encode(encoder: NewtonObjectEncoder) -> Data
    static func decode(decoder: NewtonObjectDecoder) throws -> Self
}
