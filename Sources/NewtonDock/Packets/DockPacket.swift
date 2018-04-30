
import Foundation


public protocol EncodableDockPacket {
    static var command: DockCommand { get }

    func encode() -> Data?
}


public protocol DecodableDockPacket {
    static var command: DockCommand { get }

    init(data: Data) throws
}

public protocol CodableDockPacket: EncodableDockPacket, DecodableDockPacket {}
