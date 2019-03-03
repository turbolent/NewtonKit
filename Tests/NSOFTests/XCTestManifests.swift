import XCTest

extension NSOFTests {
    static let __allTests = [
        ("testNSOF1", testNSOF1),
        ("testNSOF2", testNSOF2),
        ("testNSOF3", testNSOF3),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(NSOFTests.__allTests),
    ]
}
#endif
