
import Foundation


public struct SyncOptionsPacket: DecodableDockPacket {

    public static let command: DockCommand = .syncOptions

    // TODO: NSOF
    public let data: Data

    public init(data: Data) throws {
        self.data = data
    }
}
