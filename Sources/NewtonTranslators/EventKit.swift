
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

    if let startDateMinutesSince1904 = meeting.getInteger("mtgStartDate") {
        let startDate = Date(minutesSince1904: Int(startDateMinutesSince1904))
        event.startDate = startDate

        if let duration = meeting.getInteger("mtgDuration") {
            event.endDate = Calendar.current.date(
                byAdding: .minute,
                value: Int(duration),
                to: startDate
            )
        }
    }

    if let text = meeting.getString("mtgText") {
        event.title = text
    }

    if let modTimeMinutesSince1904 = meeting.getInteger("_modTime") {
        event.lastModifiedDate = Date(minutesSince1904: Int(modTimeMinutesSince1904))
    }

    return event
}
