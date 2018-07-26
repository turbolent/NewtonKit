
import Foundation


// MNP / V.42 error correction T-REC-V.42-199303, Annex A

/// TABLE A.1/V.42: Header-field types

internal enum MNPPacketType: UInt8 {

    /// Link request
    case LR = 1

    /// Link disconnect
    case LD = 2

    // NOTE: no 3

    /// Link transfer
    case LT = 4

    /// Link acknowledgement
    case LA = 5
}
