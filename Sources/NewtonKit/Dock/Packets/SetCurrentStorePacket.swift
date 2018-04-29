
import Foundation


public struct SetCurrentStorePacket: EncodableDockPacket {

    public static let command: DockCommand = .setCurrentStore

    public let storeFrame: NewtonFrame

    public init(storeFrame: NewtonFrame) {
        self.storeFrame = storeFrame
    }

    public func encode() -> Data? {
        return NewtonObjectEncoder.encodeRoot(newtonObject: storeFrame)
    }
}
