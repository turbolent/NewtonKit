import Foundation

extension FixedWidthInteger {

    init?(littleEndianData data: Data) {
        guard data.count == MemoryLayout<Self>.size else {
            return nil
        }

        self = data.withUnsafeBytes {
            Self(littleEndian: $0.pointee)
        }
    }

    init?(bigEndianData data: Data) {
        guard data.count == MemoryLayout<Self>.size else {
            return nil
        }

        self = data.withUnsafeBytes {
            Self(bigEndian: $0.pointee)
        }
    }

    var littleEndianData: Data {
        var littleEndian = self.littleEndian
        return withUnsafeBytes(of: &littleEndian) {
            Data($0)
        }
    }

    var bigEndianData: Data {
        var bigEndian = self.bigEndian
        return withUnsafeBytes(of: &bigEndian) {
            Data($0)
        }
    }
}
