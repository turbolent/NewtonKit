
import Foundation


public struct SynchronizePacket: CodableDockPacket {

    public static let command: DockCommand = .synchronize

    public init(data: Data) throws {}

    public func encode() -> Data? {
        return nil
    }
}
