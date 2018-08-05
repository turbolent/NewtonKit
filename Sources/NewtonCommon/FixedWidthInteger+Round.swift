
public extension FixedWidthInteger {

    func roundTowards(boundary: Self) -> Self {
        let remainder = self % boundary
        if remainder == 0 {
            return self
        }
        let padding = boundary - remainder
        return self + padding
    }
}
