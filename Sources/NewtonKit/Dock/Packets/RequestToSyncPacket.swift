
import Foundation


public struct RequestToSyncPacket: CodableDockPacket {

    public static let command: DockCommand = .requestToSync

    public init() {}

    public init(data: Data) throws {}

    public func encode() -> Data? {
        return nil
    }
}
