
import Foundation
import NSOF


public struct EntryPacket: DecodableDockPacket {

    public static let command: DockCommand = .entry

    public enum DecodingError: Error {
        case missingOrInvalidEntry
    }

    public let entry: NewtonFrame

    public init(data: Data) throws {
        guard case let (entry as NewtonFrame, _) =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            throw DecodingError.missingOrInvalidEntry
        }
        self.entry = entry
    }
}
