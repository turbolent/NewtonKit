

import Foundation


public protocol NewtonObject: class {

    func encode(encoder: NewtonObjectEncoder) -> Data
    static func decode(decoder: NewtonObjectDecoder) throws -> Self
}
