
import Foundation


public struct SyncOptionsPacket: DecodableDockPacket {

    public static let command: DockCommand = .syncOptions

    public enum DecodingError: Error {
        case missingSyncOptions
    }

    public let syncOptions: NewtonObject

    public init(data: Data) throws {
        guard case (let syncOptions?, _) =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            throw DecodingError.missingSyncOptions
        }
        self.syncOptions = syncOptions
    }
}
