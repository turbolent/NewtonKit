
import Foundation


public struct ReturnEntryPacket: EncodableDockPacket {

    public static let command: DockCommand = .returnEntry

    public let id: UInt32

    public init(id: UInt32) {
        self.id = id
    }

    public func encode() -> Data? {
        return id.bigEndianData
    }
}
