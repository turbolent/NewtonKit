
import Foundation


public struct AddedIDPacket: DecodableDockPacket {

    public static let command: DockCommand = .addedID

    public enum DecodingError: Error {
        case missingID
    }

    public let id: UInt32

    public init(data: Data) throws {
        guard let id = UInt32(bigEndianData: data) else {
            throw DecodingError.missingID
        }
        self.id = id
    }
}
