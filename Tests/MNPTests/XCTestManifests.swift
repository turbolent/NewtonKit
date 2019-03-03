import XCTest

extension MNPTests {
    static let __allTests = [
        ("testCRC", testCRC),
        ("testLinkRequestPacket", testLinkRequestPacket),
        ("testPacketLayerReadRequest", testPacketLayerReadRequest),
        ("testPacketLayerReadTransfer", testPacketLayerReadTransfer),
        ("testPacketLayerWrite", testPacketLayerWrite),
    ]
}

#if !os(macOS)
public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(MNPTests.__allTests),
    ]
}
#endif
