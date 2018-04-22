
import Foundation


public struct LastSyncTimePacket: EncodableDockPacket {

    public static let command: DockCommand = .lastSyncTime

    public init() {}

    public func encode() -> Data? {
        // TODO:
        return UInt32(0).bigEndianData
    }
}
