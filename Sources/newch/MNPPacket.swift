
import Foundation

public protocol MNPPacket {
    init(data: Data) throws
    func encode() -> Data
}


// TABLE A.1/V.42: Header-field types

internal enum MNPPacketType: UInt8 {
    case LR = 1   // Link request
    case LD = 2   // Link disconnect
    // NOTE: no 3
    case LT = 4   // Link transfer
    case LA = 5   // Link acknowledgement
}
