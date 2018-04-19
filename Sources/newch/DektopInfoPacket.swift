
import Foundation


public struct DesktopInfoPacket: EncodableDockPacket {

    public static let command: DockCommand = .desktopInfo

    public enum DesktopType: UInt32 {
        case macintosh
        case windows
    }

    public let protocolVersion: UInt32
    public let desktopType: DesktopType
    public let encryptedKey1: UInt32
    public let encryptedKey2: UInt32
    public let sessionType: DockSessionType
    public let allowSelectiveSync: Bool

    public init(protocolVersion: UInt32,
                desktopType: DesktopType,
                encryptedKey1: UInt32,
                encryptedKey2: UInt32,
                sessionType: DockSessionType,
                allowSelectiveSync: Bool) {

        self.protocolVersion = protocolVersion
        self.desktopType = desktopType
        self.encryptedKey1 = encryptedKey1
        self.encryptedKey2 = encryptedKey2
        self.sessionType = sessionType
        self.allowSelectiveSync = allowSelectiveSync
    }

    public func encode() -> Data? {
        var data = Data()
        data.append(protocolVersion.bigEndianData)
        data.append(desktopType.rawValue.bigEndianData)
        data.append(encryptedKey1.bigEndianData)
        data.append(encryptedKey2.bigEndianData)
        data.append(sessionType.rawValue.bigEndianData)
        data.append(UInt32(allowSelectiveSync ? 0 : 1).bigEndianData)
        return data
    }
}
