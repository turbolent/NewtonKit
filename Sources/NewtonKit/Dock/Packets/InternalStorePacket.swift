
import Foundation


public struct InternalStorePacket: DecodableDockPacket {

    public static let command: DockCommand = .internalStore

    // TODO: NSOF
    public let data: Data

    public init(data: Data) throws {
        self.data = data
    }
}
