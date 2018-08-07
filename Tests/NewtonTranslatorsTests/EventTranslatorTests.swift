
import Foundation
import XCTest
@testable import NewtonTranslators
import NSOF
import Html


class EventTranslatorTests: XCTestCase {

    func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: dateString)
    }

    func testEventTranslator() throws {
        let event = translateToEvent(meeting: [
            "class": "meeting" as NewtonSymbol,
            "viewStationery": "meeting" as NewtonSymbol,
            "NotesData": NewtonNil.nil,
            "mtgStartDate": 60273840 as NewtonInteger,
            "mtgText": "Dinner" as NewtonString,
            "viewBounds": NewtonNil.nil,
            "mtgInvitees": NewtonNil.nil,
            "mtgLocation": NewtonNil.nil,
            "mtgDuration": 180 as NewtonInteger,
            "mtgIconType": NewtonNil.nil,
            "mtgAlarm": NewtonNil.nil,
            "_version": 2 as NewtonInteger,
            "_modTime": 60273583 as NewtonInteger,
            "_uniqueID": 0 as NewtonInteger
        ])
        XCTAssertEqual(event, Event(
            startDate: parseDate("2018-08-06 20:00:00")!,
            endDate: parseDate("2018-08-06 23:00:00")!,
            title: "Dinner",
            lastModifiedDate: parseDate("2018-08-06 15:43:00")!
        ))
    }

    static var allTests : [(String, (EventTranslatorTests) -> () throws -> Void)] {
        return [
            ("testEventTranslator", testEventTranslator),
        ]
    }
}
