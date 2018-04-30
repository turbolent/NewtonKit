
import Foundation


public struct SetStoreToDefaultPacket: EncodableDockPacket {

    public static let command: DockCommand = .setStoreToDefault

    public init() {}

    public func encode() -> Data? {
        return nil
    }
}
