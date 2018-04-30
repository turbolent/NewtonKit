
import Foundation
import NSOF


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
    public let desktopApps: NewtonPlainArray

    public init(protocolVersion: UInt32,
                desktopType: DesktopType,
                encryptedKey: Data,
                sessionType: DockSessionType,
                allowSelectiveSync: Bool,
                desktopApps: NewtonPlainArray) throws {

        guard encryptedKey.count == DesktopInfoPacket.keySize else {
            throw InitializationError.invalidKeySize
        }

        self.protocolVersion = protocolVersion
        self.desktopType = desktopType
        self.encryptedKey = encryptedKey
        self.sessionType = sessionType
        self.allowSelectiveSync = allowSelectiveSync
        self.desktopApps = desktopApps
    }

    public func encode() -> Data? {
        var data = Data()
        data.append(protocolVersion.bigEndianData)
        data.append(desktopType.rawValue.bigEndianData)
        data.append(encryptedKey)
        data.append(sessionType.rawValue.bigEndianData)
        data.append(UInt32(allowSelectiveSync ? 1 : 0).bigEndianData)
        data.append(NewtonObjectEncoder.encodeRoot(newtonObject: desktopApps))
        return data
    }
}
