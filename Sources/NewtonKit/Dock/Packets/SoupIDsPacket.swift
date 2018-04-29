
import Foundation


public struct SoupIDsPacket: DecodableDockPacket {

    public static let command: DockCommand = .soupIDs

    public enum DecodingError: Error {
        case missingCount
        case missingID
    }

    public let ids: [UInt32]

    public init(data: Data) throws {
        var data = data
        guard let count = UInt32(bigEndianData: data) else {
            throw DecodingError.missingCount
        }
        data = data.dropFirst(MemoryLayout<UInt32>.size)

        var ids: [UInt32] = []
        for _ in 0..<count {
            guard let id = UInt32(bigEndianData: data) else {
                throw DecodingError.missingID
            }
            ids.append(id)
            data = data.dropFirst(MemoryLayout<UInt32>.size)
        }
        self.ids = ids
    }
}

