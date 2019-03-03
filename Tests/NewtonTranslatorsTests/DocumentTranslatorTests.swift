
import Foundation
import XCTest
@testable import NewtonTranslators
import NSOF
import Html


class DocumentTranslatorTests: XCTestCase {

    func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.date(from: dateString)
    }

    func testDocumentTranslator() throws {
        let document =
            translateToDocument(paperroll: [
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

        let expectedHTML = """
            <html>
              <head>
                <title>
                </title>
                <style>
                    html {
                box-sizing: border-box;
                font-family: sans-serif;
                font-size: 18px;
                line-height: 24px;
                height: 100%;
              }
              *, *:before, *:after {
                box-sizing: inherit
              }
              * {
                margin: 0;
                padding: 0;
                font-weight: normal;
                font-style: normal;
                border: 0
              }
              body {
                height: 100%
              }
              #content {
                background-image: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAgAAAA4CAAAAADlHub6AAAAFElEQVQY02P4DwUMo4xhz2BggDMASsm6VFaiatcAAAAASUVORK5CYII=');
                background-size: 4px 28px;
                margin-top: 2px;
                min-height: 100%;
              }
                </style>
              </head>
              <body>
                <div style="height: 197px"
                     id="content">
                  <p style="position: absolute;
                             left: 10px;
                             width: 113px;
                             top: 7px;
                             height: 78px">
                    This&nbsp;is&nbsp;a&nbsp;test<br><br>
                  </p>
                  <p style="position: absolute;
                             left: 322px;
                             width: 48px;
                             top: 175px;
                             height: 22px">
                    Hello!
                  </p>
                </div>
              </body>
            </html>

            """
        XCTAssertEqual(document,
                       Document(creationDate: parseDate("1996-07-08 13:00:00")!,
                                lastModifiedDate: parseDate("1996-07-08 15:31:00")!,
                                html: expectedHTML))
    }

}
