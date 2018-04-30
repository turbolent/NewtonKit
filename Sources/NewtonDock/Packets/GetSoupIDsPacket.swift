
import Foundation


public struct GetSoupIDsPacket: EncodableDockPacket {

    public static let command: DockCommand = .getSoupIDs

    public func encode() -> Data? {
        return nil
    }
}
