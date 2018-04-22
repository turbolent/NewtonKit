
import Foundation


public struct PasswordPacket: CodableDockPacket {

    public static let command: DockCommand = .password

    private static let encryptedKeySize = 8

    public enum DecodingError: Error {
        case invalidSize
    }

    public let encryptedKey: Data

    public init(encryptedKey: Data) {
        self.encryptedKey = encryptedKey
    }

    public init(data: Data) throws {
        guard data.count == PasswordPacket.encryptedKeySize else {
            throw DecodingError.invalidSize
        }

        let encryptedKeyStartIndex = data.startIndex
        let encryptedKeyEndIndex =
            encryptedKeyStartIndex.advanced(by: PasswordPacket.encryptedKeySize)
        let encryptedKey =
            data.subdata(in: encryptedKeyStartIndex..<encryptedKeyEndIndex)

        self.init(encryptedKey: encryptedKey)
    }

    public func encode() -> Data? {
        return encryptedKey
    }
}
