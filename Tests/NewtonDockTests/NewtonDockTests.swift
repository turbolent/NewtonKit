import Foundation
import XCTest
@testable import NewtonDock


class NewtonDockTests: XCTestCase {

    private func dataUnequalMessage(_ lhs: Data, _ rhs: Data) -> String {
        return "\n\(lhs.hexDump)\n\n\(rhs.hexDump)\n\n"
    }

    func testDockLayerReadRequestToDockPacket() throws {

        let initialData = Data([
            0x6e, 0x65, 0x77, 0x74,
            0x64, 0x6f, 0x63, 0x6b,
            0x72, 0x74, 0x64, 0x6b,
            0x00, 0x00, 0x00, 0x04,
            0x00, 0x00, 0x00, 0x09
        ])

        let layer = DockPacketLayer()

        var readPacket: DecodableDockPacket?

        layer.onRead = {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }
        try layer.read(data: initialData)

        guard let packet = readPacket as? RequestToDockPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet,
                       RequestToDockPacket(protocolVersion: 9))

        let encoded = try layer.write(packet: packet)
        XCTAssertEqual(encoded, initialData,
                       dataUnequalMessage(encoded, initialData))
    }

    func testDockLayerReadResultPacket() throws {

        let initialData = Data([
            0x6e, 0x65, 0x77, 0x74,
            0x64, 0x6f, 0x63, 0x6b,
            0x64, 0x72, 0x65, 0x73,
            0x00, 0x00, 0x00, 0x04,
            0x00, 0x00, 0x00, 0x00
        ])

        let layer = DockPacketLayer()

        var readPacket: DecodableDockPacket?

        layer.onRead = {
            guard readPacket == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket = $0
        }
        try layer.read(data: initialData)

        guard let packet = readPacket as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet,
                       ResultPacket(error: .ok))

        let encoded = try layer.write(packet: packet)
        XCTAssertEqual(encoded, initialData,
                       dataUnequalMessage(encoded, initialData))
    }

    func testDockLayerReadPartial() throws {

        let parts: [Data] = [
            Data([0x6e, 0x65]),
            Data([0x77, 0x74]),
            Data([0x64, 0x6f, 0x63]),
            Data([0x6b, 0x64, 0x72, 0x65, 0x73, 0x00, 0x00, 0x00]),
            Data([0x04, 0x00, 0x00]),
            Data([0x00, 0x00, 0x6e, 0x65, 0x77]),
            Data([0x74, 0x64, 0x6f, 0x63, 0x6b, 0x64, 0x72]),
            Data([0x65, 0x73, 0x00, 0x00, 0x00, 0x04, 0x00]),
            Data([0x00, 0x00, 0x00])
        ]

        let layer = DockPacketLayer()

        layer.onRead = { _ in
            XCTFail("Packet was decoded")
        }
        for part in parts[0..<5] {
            try layer.read(data: part)
        }

        var readPacket1: DecodableDockPacket?

        layer.onRead = {
            guard readPacket1 == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket1 = $0
        }
        for part in parts[5..<8] {
            try layer.read(data: part)
        }

        guard let packet1 = readPacket1 as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet1,
                       ResultPacket(error: .ok))


        var readPacket2: DecodableDockPacket?

        layer.onRead = {
            guard readPacket2 == nil else {
                XCTFail("More than one packet was decoded")
                return
            }
            readPacket2 = $0
        }
        try layer.read(data: parts.last!)

        guard let packet2 = readPacket2 as? ResultPacket else {
            XCTFail("Packet was not decoded")
            return
        }

        XCTAssertEqual(packet2,
                       ResultPacket(error: .ok))
    }

    func testDES() throws {
        let cipher = try DES(keyBytes: [0xe4, 0x0f, 0x7e, 0x9f, 0x0a, 0x36, 0x2c, 0xfa])
        XCTAssertEqual(cipher.subkeys, [
            1941816532332429047,
            3187698850721185784,
            14629649794741350207,
            2552379178741254125,
            10907857884915252627,
            925659938082994879,
            5698161420098400218,
            8738098074673864543,
            11752688268146924526,
            15095317179288608183,
            8487308217601440611,
            12601211940932366813,
            9731146212525264767,
            1318866358298834551,
            2127386486980629434,
            13864349024495151355
        ])
        let unencrypted = Data([0xff, 0x8d, 0xaa, 0xb8, 0x00, 0x20, 0x41, 0xd5])
        let encrypted = cipher.encrypt(source: unencrypted)
        let expected = Data([0xf6, 0xeb, 0xa1, 0x37, 0xf3, 0x69, 0x9e, 0xa5])
        XCTAssertEqual(encrypted, expected)
    }

}
