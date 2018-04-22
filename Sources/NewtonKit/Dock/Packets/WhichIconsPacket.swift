
import Foundation


public struct WhichIconsPacket: EncodableDockPacket {

    public static let command: DockCommand = .whichIcons

    public let iconMask: DockIconMask

    public init(iconMask: DockIconMask) {
        self.iconMask = iconMask
    }

    public func encode() -> Data? {
        return iconMask.rawValue.bigEndianData
    }
}
