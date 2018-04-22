
import Foundation


public struct DesktopInControlPacket: EncodableDockPacket {

    public static let command: DockCommand = .des

    public init() {}

    public func encode() -> Data? {
        return nil
    }
}
