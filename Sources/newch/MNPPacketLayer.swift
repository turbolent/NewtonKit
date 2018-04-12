
import Foundation

// MNP / V.42 error correction T-REC-V.42-199303, Annex A

public class MNPPacketLayer {

    public enum State {
        case outside(offset: Int)
        case inside
        case insideDLE
        case endETX
        case endCRC1
    }

    public var onStateChange: ((State, State) -> Void)?

    private var state: State = .outside(offset: 0) {
        didSet {
            onStateChange?(oldValue, state)
        }
    }

    public init() {}


    // A.3 Start-stop, octet-oriented framing mode

    // A.3.1 Start-flag field
    //
    // All frames shall begin with the three-octet, start-flag sequence SYN-DLE-STX

    private static let startFlagSequence: [UInt8] = [.SYN, .DLE, .STX]

    // A.3.4 Transparency
    //
    // [... ] The receiving error-correcting entity shall examine the
    // frame body and discard the second DLE of a two-octet DLE-DLE sequence.
    // The first DLE is considered part of the frame body field.
    // The DLE used in the start and end flag to delimit the STX and ETX
    // control octets shall not be doubled, so that they shall be recognized
    // as framing fields.

    // A.3.5 End-flag field
    //
    // All frames shall end with the two-octet, end-flag sequence DLE-ETX
    // (followed by the FCS field).

    private static let endFlagSequence: [UInt8] = [.DLE, .ETX]

    // A.3.6 Frame check sequence (FCS) field
    //
    // The FCS is a 16-bit sequence generated by the cyclic redundancy check (CRC)
    // polynomial x16 + x15 + x2 + 1. The frame body and ETX octet of the stop flag
    // are included in the FCS calculation. The start flag and all DLE octets used
    // to maintain data transparency (see A.3.4) are excluded from the FCS calculation.

    // 8.1.3 Invalid frames
    //
    // Invalid frames shall be discarded without notification to the sender
    // (however, see 8.5.4). No action is taken as a result of having received the frame.

    private var rawPacket = RawPacket()

    private func leavePacket() {
        state = .outside(offset: 0)
    }

    public func read(data: Data, handler: (MNPPacket) -> Void) throws {
        for byte in data {
            switch state {
            case .outside(let offset):
                let sequence = MNPPacketLayer.startFlagSequence
                guard byte == sequence[offset] else {
                    leavePacket()
                    break
                }
                let newOffset = offset + 1
                if newOffset == sequence.count {
                    state = .inside
                    rawPacket = RawPacket()
                } else {
                    state = .outside(offset: newOffset)
                }
            case .inside:
                rawPacket.append(byte)
                if byte == .DLE {
                    state = .insideDLE
                } else {
                    rawPacket.updateCalculatedCRC(byte)
                }
            case .insideDLE:
                switch byte {
                case .DLE:
                    state = .inside
                case .ETX:
                    rawPacket.updateCalculatedCRC(byte)
                    state = .endETX
                default:
                    leavePacket()
                }
            case .endETX:
                rawPacket.resetReceivedCRC(byte)
                state = .endCRC1
            case .endCRC1:
                leavePacket()
                rawPacket.updateReceivedCRC(byte)
                if rawPacket.crcMatches {
                    let packet = try rawPacket.decode()
                    handler(packet)
                }
            }
        }
    }

    private struct RawPacket {

        var data = Data()
        var receivedCRC: UInt16 = 0
        var calculatedCRC: UInt16 = 0

        mutating func append(_ byte: UInt8) {
            data.append(byte)
        }

        mutating func updateCalculatedCRC(_ byte: UInt8) {
            calculatedCRC = crc16(input: byte, crc: calculatedCRC)
        }

        mutating func resetReceivedCRC(_ byte: UInt8) {
            receivedCRC = UInt16(byte)
        }

        mutating func updateReceivedCRC(_ byte: UInt8) {
            receivedCRC += UInt16(byte) << 8
        }

        var crcMatches: Bool {
            return receivedCRC == calculatedCRC
        }

        enum DecodingError: Error {
            case invalidSize
            case invalidType
        }

        // A.6.2.1 Fixed parameter 0 – Length indication
        //
        // The length indication shall be the first octet of the header field.
        // The value of the length indication determines the total length
        // of the header field, in octets. This length value does not include
        // the length indication itself.
        //
        // The value of 255 shall be used to indicate that the next two octets
        // constitute a 16-bit extended length indication.
        //
        // The length indication requires three octets to represent lengths
        // over 254 octets.

        func decode() throws -> MNPPacket {
            guard self.data.count >= 2 else {
                throw DecodingError.invalidSize
            }

            let headerLength: UInt16
            let packetType: MNPPacketType
            let data: Data

            if self.data[0] == 255 {
                headerLength = UInt16(self.data[1]) * 256 + UInt16(self.data[2])
                guard let type = MNPPacketType(rawValue: self.data[3]) else {
                    throw DecodingError.invalidType
                }
                packetType = type
                data = self.data.dropFirst(4)
            } else {
                headerLength = UInt16(self.data[0])
                guard let type = MNPPacketType(rawValue: self.data[1]) else {
                    throw DecodingError.invalidType
                }
                packetType = type
                data = self.data.dropFirst(2)
            }

            switch packetType {
            case .LR:
                return try MNPLinkRequestPacket(data: data)
            case .LA:
                return try MNPLinkAcknowledgementPacket(data: data)
            case .LD:
                return try MNPLinkDisconnectPacket(data: data)
            case .LT:
                return try MNPLinkTransferPacket(data: data)
            }
        }
    }

    public func write(data: Data) -> Data {
        var result = Data()
        var crc: UInt16 = 0
        result.append(contentsOf: MNPPacketLayer.startFlagSequence)
        for byte in data {
            result.append(byte)
            crc = crc16(input: byte, crc: crc)
            if byte == .DLE {
                result.append(.DLE)
            }
        }
        result.append(contentsOf: MNPPacketLayer.endFlagSequence)
        crc = crc16(input: .ETX, crc: crc)
        result.append(contentsOf: crc.littleEndianBytes)
        return result
    }
}

