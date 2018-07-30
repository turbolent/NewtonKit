
import Foundation

public extension Data {

    func slice(_ length: Int, startIndex: Index? = nil) -> (Data, Index)? {
        let startIndex = startIndex ?? self.startIndex
        let endIndex = startIndex.advanced(by: length)
        guard endIndex <= self.endIndex else {
            return nil
        }
        let slice = subdata(in: startIndex..<endIndex)
        return (slice, endIndex)
    }

    func sliceBigEndian<T>(startIndex: Index? = nil) -> (T, Index)? where T: FixedWidthInteger {
        guard case let (data, endIndex)? = slice(MemoryLayout<T>.size, startIndex: startIndex) else {
            return nil
        }
        guard let integer = T(bigEndianData: data) else {
            return nil
        }
        return (integer, endIndex)
    }

    func sliceLittleEndian<T>(startIndex: Index? = nil) -> (T, Index)? where T: FixedWidthInteger {
        guard case let (data, endIndex)? = slice(MemoryLayout<T>.size, startIndex: startIndex) else {
            return nil
        }
        guard let integer = T(littleEndianData: data) else {
            return nil
        }
        return (integer, endIndex)
    }
}
