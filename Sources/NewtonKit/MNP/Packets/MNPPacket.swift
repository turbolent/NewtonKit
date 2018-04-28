
import Foundation


public protocol MNPPacket {
    init(data: Data) throws
    func encode() -> Data
}
