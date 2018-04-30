
import Foundation
import NSOF


public struct SetStoreGetNamesPacket: EncodableDockPacket {

    public static let command: DockCommand = .setStoreGetNames

    public let storeFrame: NewtonFrame

    public init(storeFrame: NewtonFrame) {
        self.storeFrame = storeFrame
    }

    public func encode() -> Data? {
        return NewtonObjectEncoder.encodeRoot(newtonObject: storeFrame)
    }
}
