
import Foundation
import XCTest
@testable import NewtonTranslators
import NSOF
import Html


class NewtonTranslatorsTests: XCTestCase {

    func testHtmlTranslator() throws {
        let document =
            translateToHtmlDocument(paperroll: [
                "class": "paperroll" as NewtonSymbol,
                "viewStationery": "paperroll" as NewtonSymbol,
                "height": 360 as NewtonInteger,
                "data": [
                    [
                        "viewStationery": "para" as NewtonSymbol,
                        "viewBounds": [
                            "left": 322 as NewtonInteger,
                            "top": 175 as NewtonInteger,
                            "right": 370 as NewtonInteger,
                            "bottom": 197 as NewtonInteger
                            ] as NewtonFrame,
                        "text": "Hello!" as NewtonString
                        ] as NewtonFrame,
                    [
                        "viewStationery": "para" as NewtonSymbol,
                        "viewBounds": NewtonSmallRect(top: 7, left: 10, bottom: 85, right: 123),
                        "text": "This is a test\r\r" as NewtonString
                        ] as NewtonFrame,
                    ] as NewtonPlainArray,
                "timestamp": 48661260 as NewtonInteger,
                "_version": 2 as NewtonInteger,
                "_modTime": 48661411 as NewtonInteger,
                "_uniqueID": 0 as NewtonInteger
            ])
        print(render(document, config: pretty))
    }

    static var allTests : [(String, (NewtonTranslatorsTests) -> () throws -> Void)] {
        return [
            ("testHtmlTranslator", testHtmlTranslator),
        ]
    }
}
