
import Foundation


public struct GetInternalStorePacket: EncodableDockPacket {

    public static let command: DockCommand = .getInternalStore

    public init() {}

    public func encode() -> Data? {
        return nil
    }
}
