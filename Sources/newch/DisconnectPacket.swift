
import Foundation


public struct DisconnectPacket: CodableDockPacket {

    public static let command: DockCommand = .disconnect

    public init() {}

    public init(data: Data) throws {}

    public func encode() -> Data? {
        return nil
    }
}
