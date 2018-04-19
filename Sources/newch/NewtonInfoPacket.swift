
import Foundation


public struct NewtonInfoPacket: DecodableDockPacket {

    public static let command: DockCommand = .newtonInfo

    public enum DecodingError: Error {
        case invalidSize
        case invalidProtocolVersion
        case invalidEncryptedKey1
        case invalidEncryptedKey2
    }

    public let protocolVersion: UInt32
    public let encryptedKey1: UInt32
    public let encryptedKey2: UInt32

    public init(protocolVersion: UInt32,
                encryptedKey1: UInt32,
                encryptedKey2: UInt32) {

        self.protocolVersion = protocolVersion
        self.encryptedKey1 = encryptedKey1
        self.encryptedKey2 = encryptedKey2
    }

    public init(data: Data) throws {
        let fieldSize = MemoryLayout<UInt32>.size
        guard data.count == 3 * fieldSize else {
            throw DecodingError.invalidSize
        }

        guard
            let protocolVersion = UInt32(bigEndianData: data)
        else {
            throw DecodingError.invalidProtocolVersion
        }

        guard
            let encryptedKey1 =
                UInt32(bigEndianData: data.advanced(by: fieldSize))
        else {
            throw DecodingError.invalidEncryptedKey1
        }

        guard
            let encryptedKey2 =
                UInt32(bigEndianData: data.advanced(by: 2 * fieldSize))
        else {
            throw DecodingError.invalidEncryptedKey2
        }

        self.init(protocolVersion: protocolVersion,
                  encryptedKey1: encryptedKey1,
                  encryptedKey2: encryptedKey2)
    }
}
