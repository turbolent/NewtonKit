import XCTest

extension NewtonDockTests {
    static let __allTests = [
        ("testDES", testDES),
        ("testDockLayerReadPartial", testDockLayerReadPartial),
        ("testDockLayerReadRequestToDockPacket", testDockLayerReadRequestToDockPacket),
        ("testDockLayerReadResultPacket", testDockLayerReadResultPacket),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(NewtonDockTests.__allTests),
    ]
}
#endif
