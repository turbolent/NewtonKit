
import Foundation


public extension Data {
    func chunk(n: Int) -> [Data] {
        return stride(from: 0, to: count, by: n)
            .map { startOffset in
                let startIndex = self.startIndex.advanced(by: startOffset)
                let endIndex = Swift.min(startIndex.advanced(by: n), self.endIndex)
                return subdata(in: startIndex..<endIndex)
            }
    }
}
