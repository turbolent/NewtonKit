
import Foundation


public struct StartKeyboardPassthroughPacket: CodableDockPacket {

    public static let command: DockCommand = .startKeyboardPassthrough

    public init() {}

    public init(data: Data) throws {}

    public func encode() -> Data? {
        return nil
    }
}

