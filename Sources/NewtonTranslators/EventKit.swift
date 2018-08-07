
import Foundation
import NSOF

public struct Event: Equatable {
    var startDate: Date?
    var endDate: Date?
    var title: String?
    var lastModifiedDate: Date?
}

public func translateToEvent(meeting: NewtonFrame) -> Event {
    var event = Event()

    if let startDateMinutesSince1904 = (meeting["mtgStartDate"] as? NewtonInteger)?.integer {
        let startDate = Date(minutesSince1904: Int(startDateMinutesSince1904))
        event.startDate = startDate

        if let duration = (meeting["mtgDuration"] as? NewtonInteger)?.integer {
            event.endDate = Calendar.current.date(
                byAdding: .minute,
                value: Int(duration),
                to: startDate
            )
        }
    }

    if let text = (meeting["mtgText"] as? NewtonString)?.string {
        event.title = text
    }

    if let modTimeMinutesSince1904 = (meeting["_modTime"] as? NewtonInteger)?.integer {
        event.lastModifiedDate = Date(minutesSince1904: Int(modTimeMinutesSince1904))
    }

    return event
}
