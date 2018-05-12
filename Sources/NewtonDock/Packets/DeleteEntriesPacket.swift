
import Foundation


public struct DeleteEntriesPacket: EncodableDockPacket {

    public static let command: DockCommand = .deleteEntries

    public let ids: [UInt32]

    public init(ids: [UInt32]) {
        self.ids = ids
    }

    public func encode() -> Data? {
        var data = Data()
        data.append(UInt32(ids.count).bigEndianData)
        for id in ids {
            data.append(id.bigEndianData)
        }
        return data
    }
}
