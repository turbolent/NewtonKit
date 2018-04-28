
import Foundation


public struct InternalStorePacket: DecodableDockPacket {

    public static let command: DockCommand = .internalStore

    public enum DecodingError: Error {
        case missingInternalStore
    }

    public let internalStore: NewtonObject

    public init(data: Data) throws {
        guard let internalStore =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            throw DecodingError.missingInternalStore
        }
        self.internalStore = internalStore
    }
}
