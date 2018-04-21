
import Foundation


public struct NewtonInfoPacket: DecodableDockPacket {

    public static let command: DockCommand = .newtonInfo

    private static let protocolVersionSize = MemoryLayout<UInt32>.size
    private static let encryptedKeySize = 8
    private static let requiredSize = protocolVersionSize + encryptedKeySize

    public enum DecodingError: Error {
        case invalidSize
        case invalidProtocolVersion
    }

    public let protocolVersion: UInt32
    public let encryptedKey: Data

    public init(data: Data) throws {
        guard data.count == NewtonInfoPacket.requiredSize else {
            throw DecodingError.invalidSize
        }

        guard
            let protocolVersion = UInt32(bigEndianData: data)
        else {
            throw DecodingError.invalidProtocolVersion
        }
        self.protocolVersion = protocolVersion

        let encryptedKeyStartIndex =
            data.startIndex.advanced(by: NewtonInfoPacket.protocolVersionSize)
        let encryptedKeyEndIndex =
            encryptedKeyStartIndex.advanced(by: NewtonInfoPacket.encryptedKeySize)
        encryptedKey = data.subdata(in: encryptedKeyStartIndex..<encryptedKeyEndIndex)
    }
}
