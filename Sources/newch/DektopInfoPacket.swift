
import Foundation


public struct DesktopInfoPacket: DockPacket {

    public static let command: DockCommand = .desktopInfo

    public init() {}

    public func encode() -> Data? {
        return nil
    }
}
