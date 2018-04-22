
import Foundation


public struct GetSyncOptionsPacket: EncodableDockPacket {

    public static let command: DockCommand = .getSyncOptions

    public func encode() -> Data? {
        return nil
    }
}
