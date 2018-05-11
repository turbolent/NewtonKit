
import Foundation

public extension Date {
    init(minutesSince1904: Int) {
        self.init(timeIntervalSinceReferenceDate:
            -kCFAbsoluteTimeIntervalSince1904
            + Double(minutesSince1904) * 60.0
        )
    }
}
