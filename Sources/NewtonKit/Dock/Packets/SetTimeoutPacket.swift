
import Foundation


public struct SetTimeoutPacket: EncodableDockPacket {

    public static let command: DockCommand = .setTimeout

    public let timeout: UInt32

    public init(timeout: UInt32) {
        self.timeout = timeout
    }

    public func encode() -> Data? {
        return timeout.bigEndianData
    }
}
