import Foundation

extension FixedWidthInteger {

    public init?(littleEndianData data: Data) {
        guard data.count >= MemoryLayout<Self>.size else {
            return nil
        }

        self = data.withUnsafeBytes {
            Self(littleEndian: $0.pointee)
        }
    }

    public init?(bigEndianData data: Data) {
        guard data.count >= MemoryLayout<Self>.size else {
            return nil
        }

        self = data.withUnsafeBytes {
            Self(bigEndian: $0.pointee)
        }
    }

    public var littleEndianData: Data {
        var littleEndian = self.littleEndian
        return withUnsafeBytes(of: &littleEndian) {
            Data($0)
        }
    }

    public var bigEndianData: Data {
        var bigEndian = self.bigEndian
        return withUnsafeBytes(of: &bigEndian) {
            Data($0)
        }
    }
}
