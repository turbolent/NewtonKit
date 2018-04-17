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

    func testPacketLayerReadRequest() throws {

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

        var readPacket: MNPPacket?

        try layer.read(data: data) {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }

        guard let packet = readPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssert(packet is MNPLinkRequestPacket)
    }

    func testPacketLayerReadTransfer() throws {

        let layer = MNPPacketLayer()
        let data = Data(bytes: [
            0x16, 0x10, 0x02, 0x02, 0x04, 0x02, 0x6e, 0x65,
            0x77, 0x74, 0x64, 0x6f, 0x63, 0x6b, 0x6e, 0x61,
            0x6d, 0x65, 0x00, 0x00, 0x00, 0x5a, 0x00, 0x00,
            0x00, 0x38, 0xee, 0xe6, 0x53, 0x96, 0x01, 0x00,
            0x00, 0x00, 0x00, 0x72, 0x63, 0x77, 0x00, 0x02,
            0x00, 0x01, 0x00, 0x00, 0x80, 0x00, 0x00, 0x10,
            0x10, 0x00, 0x00, 0x00, 0x00, 0x01, 0x40, 0x00,
            0x00, 0x00, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x01, 0x1c, 0xe3, 0xa4, 0x1d, 0x00,
            0x00, 0x00, 0x55, 0x00, 0x00, 0x00, 0x55, 0x00,
            0x00, 0x00, 0x01, 0x00, 0x42, 0x00, 0x61, 0x00,
            0x73, 0x00, 0x74, 0x00, 0x69, 0x00, 0x61, 0x00,
            0x6e, 0x00, 0x20, 0x00, 0x4d, 0x00, 0xfc, 0x00,
            0x6c, 0x00, 0x6c, 0x00, 0x65, 0x00, 0x72, 0x00,
            0x00, 0x00, 0x00, 0x10, 0x03, 0xf6, 0xc9
        ])

        var readPacket: MNPPacket?

        try layer.read(data: data) {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }

        guard let packet = readPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssert(packet is MNPLinkTransferPacket)
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
        XCTAssertEqual(crc16(input: [
            0x02, 0x04, 0x02, 0x6e, 0x65, 0x77, 0x74, 0x64,
            0x6f, 0x63, 0x6b, 0x6e, 0x61, 0x6d, 0x65, 0x00,
            0x00, 0x00, 0x5a, 0x00, 0x00, 0x00, 0x38, 0xee,
            0xe6, 0x53, 0x96, 0x01, 0x00, 0x00, 0x00, 0x00,
            0x72, 0x63, 0x77, 0x00, 0x02, 0x00, 0x01, 0x00,
            0x00, 0x80, 0x00, 0x00, 0x10, 0x00, 0x00, 0x00,
            0x00, 0x01, 0x40, 0x00, 0x00, 0x00, 0xf0, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x1c,
            0xe3, 0xa4, 0x1d, 0x00, 0x00, 0x00, 0x55, 0x00,
            0x00, 0x00, 0x55, 0x00, 0x00, 0x00, 0x01, 0x00,
            0x42, 0x00, 0x61, 0x00, 0x73, 0x00, 0x74, 0x00,
            0x69, 0x00, 0x61, 0x00, 0x6e, 0x00, 0x20, 0x00,
            0x4d, 0x00, 0xfc, 0x00, 0x6c, 0x00, 0x6c, 0x00,
            0x65, 0x00, 0x72, 0x00, 0x00, 0x00, 0x00,
            0x03
        ]), 0xC9F6)
    }

    func testDockLayerReadRequestToDockPacket() throws {

        let initialData = Data(bytes: [
            0x6e, 0x65, 0x77, 0x74,
            0x64, 0x6f, 0x63, 0x6b,
            0x72, 0x74, 0x64, 0x6b,
            0x00, 0x00, 0x00, 0x04,
            0x00, 0x00, 0x00, 0x09
        ])

        let layer = DockPacketLayer()

        var readPacket: DockPacket?

        try layer.read(data: initialData) {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }

        guard let packet = readPacket as? RequestToDockPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet,
                       RequestToDockPacket(protocolVersion: 9))
        XCTAssertEqual(try layer.write(packet: packet), initialData)
    }

    func testDockLayerReadResultPacket() throws {

        let initialData = Data(bytes: [
            0x6e, 0x65, 0x77, 0x74,
            0x64, 0x6f, 0x63, 0x6b,
            0x64, 0x72, 0x65, 0x73,
            0x00, 0x00, 0x00, 0x04,
            0x00, 0x00, 0x00, 0x00
        ])

        let layer = DockPacketLayer()

        var readPacket: DockPacket?

        try layer.read(data: initialData) {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }

        guard let packet = readPacket as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet,
                       ResultPacket(errorCode: 0))
        XCTAssertEqual(try layer.write(packet: packet), initialData)
    }

    func testDockLayerReadPartial() throws {

        let parts = [
            Data(bytes: [0x6e, 0x65]),
            Data(bytes: [0x77, 0x74]),
            Data(bytes: [0x64, 0x6f, 0x63]),
            Data(bytes: [0x6b, 0x64, 0x72, 0x65, 0x73, 0x00, 0x00, 0x00]),
            Data(bytes: [0x04, 0x00, 0x00]),
            Data(bytes: [0x00, 0x00, 0x6e, 0x65, 0x77]),
            Data(bytes: [0x74, 0x64, 0x6f, 0x63, 0x6b, 0x64, 0x72]),
            Data(bytes: [0x65, 0x73, 0x00, 0x00, 0x00, 0x04, 0x00]),
            Data(bytes: [0x00, 0x00, 0x01])
        ]

        let layer = DockPacketLayer()

        for part in parts[0..<5] {
            try layer.read(data: part) { _ in
                XCTFail("Packet was decoded")
            }
        }

        var readPacket1: DockPacket?

        for part in parts[5..<8] {
            try layer.read(data: part) {
                guard readPacket1 == nil else {
                    XCTFail("More than one packet was decoded")
                    return
                }
                readPacket1 = $0
            }
        }

        guard let packet1 = readPacket1 as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet1,
                       ResultPacket(errorCode: 0))


        var readPacket2: DockPacket?

        try layer.read(data: parts.last!) {
            guard readPacket2 == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket2 = $0
        }

        guard let packet2 = readPacket2 as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet2,
                       ResultPacket(errorCode: 1))
    }



    static var allTests : [(String, (newchTests) -> () throws -> Void)] {
        return [
            ("testPacketLayerReadRequest", testPacketLayerReadRequest),
            ("testPacketLayerReadTransfer", testPacketLayerReadTransfer),
            ("testPacketLayerWrite", testPacketLayerWrite),
            ("testLinkRequestPacket", testLinkRequestPacket),
            ("testCRC", testCRC),
            ("testDockLayerReadRequestToDockPacket", testDockLayerReadRequestToDockPacket),
            ("testDockLayerReadResultPacket", testDockLayerReadResultPacket),
            ("testDockLayerReadPartial", testDockLayerReadPartial)
        ]
    }
}
