import Foundation

public extension FixedWidthInteger {

    private static func loadNative(data: Data) -> Self? {
        guard data.count >= MemoryLayout<Self>.size else {
            return nil
        }

        // Copy the data to avoid loading from unaligned data
        let endIndex = data.startIndex.advanced(by: MemoryLayout<Self>.size)
        let range = data.startIndex..<endIndex

        return data
            .subdata(in: range)
            .withUnsafeBytes { $0.load(as: Self.self) }
    }

    init?(littleEndianData data: Data) {
        guard let native = Self.loadNative(data: data) else {
            return nil
        }
        self = native.littleEndian
    }

    init?(bigEndianData data: Data) {
        guard let native = Self.loadNative(data: data) else {
            return nil
        }
        self = native.bigEndian
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
