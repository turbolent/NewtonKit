
import Foundation


public struct SendSoupPacket: EncodableDockPacket {

    public static let command: DockCommand = .sendSoup

    public func encode() -> Data? {
        return nil
    }
}

