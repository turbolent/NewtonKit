
import Foundation


public struct DesktopInControlPacket: EncodableDockPacket {

    public static let command: DockCommand = .desktopInControl

    public init() {}

    public func encode() -> Data? {
        return nil
    }
}
