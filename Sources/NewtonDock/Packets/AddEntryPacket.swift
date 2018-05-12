
import Foundation
import NSOF


public struct AddEntryPacket: EncodableDockPacket {

    public static let command: DockCommand = .addEntry

    public enum DecodingError: Error {
        case missingOrInvalidEntry
    }

    public let entry: NewtonFrame

    public func encode() -> Data? {
        return NewtonObjectEncoder.encodeRoot(newtonObject: entry)
    }
}
