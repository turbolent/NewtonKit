import Foundation
import XCTest
@testable import newch

extension Data {
    var debugDescription: String {
        return map { String(format: "%x", $0) }
            .joined(separator: ", ")
    }
}

class newchTests: XCTestCase {

    func testPacketLayerRead() throws {

        let layer = MNPPacketLayer()
        let data = Data(bytes: [
            0x16, 0x10, 0x2,  // start sequence

            // header
            0x26,  // length of header
            0x1,  // type = LR
            0x2,  // constant parameter 1
            0x1, 0x6, 0x1, 0x0, 0x0, 0x0, 0x0, 0xff,  // constant parameter 2
            0x2, 0x1, 0x2,  // framing mode = 0x2
            0x3, 0x1, 0x8,  // max outstanding LT frames = 0x8
            0x4, 0x2, 0x40, 0x0,  // max info length = 64
            0x8, 0x1, 0x3,  // max info length 256 enabled, fixed field LT and LA frames enabled

            // other information
            0x9, 0x1, 0x1, 0xe, 0x4, 0x3, 0x4, 0x0, 0xfa, 0xc5, 0x6, 0x1, 0x4, 0x0, 0x0, 0xe1, 0x0,

            0x10, 0x3, 0xb9, 0xbf  // end sequence with CRC
        ])

        let packetDecoded = expectation(description: "packet is decoded")
        var packet: MNPPacket?

        try layer.read(data: data) {
            guard packet == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            packet = $0
            packetDecoded.fulfill()
        }

        wait(for: [packetDecoded], timeout: 0)

        XCTAssert(packet is MNPLinkRequestPacket)
    }

    func testPacketLayerWrite() {
        let layer = MNPPacketLayer()
        let data = Data(bytes: [0xF0, 0xF1, 0xF2, .DLE, 0xF3, 0xF4])
        let result = layer.write(data: data)
        let expected = Data(bytes: [
            0x16, 0x10, 0x02,  // start sequence
            0xF0, 0xF1, 0xF2, .DLE, .DLE, 0xF3, 0xF4,  // data, with escaped DLE
            0x10, 0x03, 0x2e, 0xc9  // end sequence with CRC
        ])
        XCTAssertEqual(result as NSData, expected as NSData)
    }

    func testLinkRequestPacket() throws {

        let initialData = Data(bytes: [
            0x2,  // constant parameter 1
            0x1, 0x6, 0x1, 0x0, 0x0, 0x0, 0x0, 0xff,  // constant parameter 2
            0x2, 0x1, 0x2,  // framing mode = 0x2
            0x3, 0x1, 0x8,  // max outstanding LT frames = 0x8
            0x4, 0x2, 0x40, 0x0,  // max info length = 64
            0x8, 0x1, 0x3,  // max info length 256 enabled, fixed field LT and LA frames enabled
        ])

        let linkRequestPacket = try MNPLinkRequestPacket(data: initialData)

        XCTAssertEqual(linkRequestPacket.maxOutstandingLTFrameCount, 0x8)
        XCTAssertEqual(linkRequestPacket.maxInfoLength, 64)
        XCTAssertTrue(linkRequestPacket.maxInfoLength256)
        XCTAssertTrue(linkRequestPacket.fixedFieldLTAndLAFrames)

        let expectedEncoding = Data(bytes: [
            // header
            0x17, // length of header = 23
            0x1,  // type = LR
            0x2,  // constant parameter 1
            0x1, 0x6, 0x1, 0x0, 0x0, 0x0, 0x0, 0xff,  // constant parameter 2
            0x2, 0x1, 0x2,  // framing mode = 0x2
            0x3, 0x1, 0x8,  // max outstanding LT frames = 0x8
            0x4, 0x2, 0x40, 0x0,  // max info length = 64
            0x8, 0x1, 0x3  // max info length 256 enabled, fixed field LT and LA frames enabled
        ])

        XCTAssertEqual(linkRequestPacket.encode(), expectedEncoding)
    }

    func testCRC() {
        XCTAssertEqual(crc16(input: [UInt8]("123456789".utf8)), 0xbb3d)
        XCTAssertEqual(crc16(input: [UInt8]("ZYX".utf8)), 0xb91b)
    }

    static var allTests : [(String, (newchTests) -> () throws -> Void)] {
        return [
            ("testPacketLayerRead", testPacketLayerRead),
            ("testPacketLayerWrite", testPacketLayerWrite),
            ("testLinkRequestPacket", testLinkRequestPacket),
            ("testCRC", testCRC),

        ]
    }
}
