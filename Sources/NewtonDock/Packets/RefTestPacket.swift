
import Foundation
import NSOF


public struct RefTestPacket: CodableDockPacket {

    public static let command: DockCommand = .refTest

    public enum DecodingError: Error {
        case invalidEntry
    }

    public let object: NewtonObject?

    public init(object: NewtonObject? = nil) {
        self.object = object
    }

    public init(data: Data) throws {
        if data.isEmpty {
            self.init()
        } else {
            guard case let (object?, _) =
                try NewtonObjectDecoder.decodeRoot(data: data)
            else {
                throw DecodingError.invalidEntry
            }
            self.init(object: object)
        }
    }

    public func encode() -> Data? {
        if let object = object {
            return NewtonObjectEncoder.encodeRoot(newtonObject: object)
        } else {
            return Data()
        }
    }
}
