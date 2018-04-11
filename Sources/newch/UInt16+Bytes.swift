import Foundation

extension UInt16 {
    init?(littleEndianBytes bytes: [UInt8]) {
        guard bytes.count == 2 else {
            return nil
        }

        self = UInt16(bytes[0]) | UInt16(bytes[1]) << 8
    }

    var littleEndianBytes: [UInt8] {
        return [
            UInt8(self & 0xff),
            UInt8(self >> 8)
        ]
    }
}
