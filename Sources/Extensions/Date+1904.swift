
import Foundation
import CoreFoundation

public extension Date {
    init(minutesSince1904: Int) {
        self.init(secondsSince1904: minutesSince1904 * 60)
    }

    init(secondsSince1904: Int) {
        self.init(timeIntervalSinceReferenceDate:
            -kCFAbsoluteTimeIntervalSince1904
            + Double(secondsSince1904)
        )
    }
}
