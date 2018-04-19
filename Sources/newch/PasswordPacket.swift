
import Foundation


public struct PasswordPacket: CodableDockPacket {

    public static let command: DockCommand = .password

    public enum DecodingError: Error {
        case invalidSize
        case invalidEncryptedKey1
        case invalidEncryptedKey2
    }

    public let encryptedKey1: UInt32
    public let encryptedKey2: UInt32

    public init(encryptedKey1: UInt32,
                encryptedKey2: UInt32) {

        self.encryptedKey1 = encryptedKey1
        self.encryptedKey2 = encryptedKey2
    }

    public init(data: Data) throws {
        let fieldSize = MemoryLayout<UInt32>.size
        guard data.count == 2 * fieldSize else {
            throw DecodingError.invalidSize
        }

        guard let encryptedKey1 = UInt32(bigEndianData: data) else {
            throw DecodingError.invalidEncryptedKey1
        }

        guard
            let encryptedKey2 =
                UInt32(bigEndianData: data.advanced(by: fieldSize))
        else {
            throw DecodingError.invalidEncryptedKey2
        }

        self.init(encryptedKey1: encryptedKey1,
                  encryptedKey2: encryptedKey2)
    }

    public func encode() -> Data? {
        var data = Data()
        data.append(encryptedKey1.bigEndianData)
        data.append(encryptedKey2.bigEndianData)
        return data
    }
}
