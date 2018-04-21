
import Foundation


public struct DesktopInfoPacket: EncodableDockPacket {

    public static let command: DockCommand = .desktopInfo

    public enum InitializationError: Error {
        case invalidKeySize
    }

    public static let keySize = 8

    public enum DesktopType: UInt32 {
        case macintosh
        case windows
    }

    public let protocolVersion: UInt32
    public let desktopType: DesktopType
    public let encryptedKey: Data
    public let sessionType: DockSessionType
    public let allowSelectiveSync: Bool

    public init(protocolVersion: UInt32,
                desktopType: DesktopType,
                encryptedKey: Data,
                sessionType: DockSessionType,
                allowSelectiveSync: Bool) throws {

        guard encryptedKey.count == DesktopInfoPacket.keySize else {
            throw InitializationError.invalidKeySize
        }

        self.protocolVersion = protocolVersion
        self.desktopType = desktopType
        self.encryptedKey = encryptedKey
        self.sessionType = sessionType
        self.allowSelectiveSync = allowSelectiveSync
    }

    public func encode() -> Data? {
        var data = Data()
        data.append(protocolVersion.bigEndianData)
        data.append(desktopType.rawValue.bigEndianData)
        data.append(encryptedKey)
        data.append(sessionType.rawValue.bigEndianData)
        data.append(UInt32(allowSelectiveSync ? 0 : 1).bigEndianData)
        return data
    }
}
