
import Foundation


public protocol DockPacket {
    static var command: DockCommand { get }
    func encode() -> Data?
}


public protocol DecodableDockPacket: DockPacket {
    init(data: Data) throws
}
