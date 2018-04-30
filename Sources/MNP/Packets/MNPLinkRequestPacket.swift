
import Foundation
import Extensions


// MNP / V.42 error correction T-REC-V.42-199303, Annex A

// A.6.4.1 Link request (LR) frame
//
// The link request (LR) frame is used to establish an error-corrected connection
// between two error-correcting entities with an active physical connection.
// The LR frame is also used to negotiate operational parameters to be in effect
// for the duration of the error-corrected connection (see A.7.1.5).

// TABLE A.2/V.42: Link request header-field parameters

public struct MNPLinkRequestPacket: MNPPacket {

    public enum DecodingError: Error {
        case invalidSize
        case invalidMaxInfoLength
        case invalidFramingMode
    }

    public enum ValidationError {
        case invalidConstantParameter1
        case invalidConstantParameter2
    }


    // A.6.4.1.3 Fixed parameter 2 – Constant parameter 1
    //
    // This constant parameter shall be the third octet of the header field.
    // The value of this constant is an octet value of 2.

    private static let constantParameter1 = Data(bytes: [0x2])


    // A.6.4.1.4 Variable parameter 1 – Constant parameter 2
    //
    // This constant parameter shall be an octet sequence of value (1,6,1,0,0,0,0,255).

    private static let constantParameter2 =
        Data(bytes: [0x1, 0x6, 0x1, 0x0, 0x0, 0x0, 0x0, 0xff])


    // A.6.4.1.5 Variable parameter 2 – Framing mode parameter
    //
    // The framing mode parameter defines the framing mode to be used
    // on the error-corrected connection.
    //
    // Two-way simultaneous, start-stop, octet-oriented framing mode
    // shall be represented by framing mode 2.
    //
    // Two-way simultaneous, bit-oriented framing mode shall be
    // represented by framing mode 3.

    public enum FramingMode: UInt8 {
        case startStopOctetOriented = 2
        case bitOriented = 3
    }

    public let framingMode: FramingMode


    // A.6.4.1.6 Variable parameter 3 –
    // Maximum number of outstanding LT frames parameter, k
    //
    // The maximum number of outstanding LT frames parameter, k,
    // defines the maximum number of LT frames with maximum-length
    // information fields that an error-correcting entity may send
    // at a given time without waiting for an acknowledgement.
    // The value of k shall never exceed the sequence number
    // modulus minus 1.

    public let maxOutstandingLTFrameCount: UInt8


    // A.6.4.1.7 Variable parameter 4 –
    // Maximum information field length parameter N401
    //
    // The maximum information-field length parameter, N401, defines
    // the maximum length of user data, in octets, that can be sent
    // in the information field of the link transfer (LT) frame.

    public let maxInfoLength: UInt16

    // A.6.4.1.8 Variable parameter 8 – Data phase optimization
    //
    // The data phase optimization parameter defines optional
    // facilities that may be supported on an error-corrected
    // connection to improve data throughput.
    //
    // The value of this parameter is a bit map that indicates
    // protocol facilities to be used, as follows:
    //  - bit 1: 1 = maximum information-field length of 256 octets;
    //  - bit 2: 1 = fixed field LT and LA frames;
    //  - bit 3-8: reserved.

    public let maxInfoLength256: Bool
    public let fixedFieldLTAndLAFrames: Bool


    public let validationErrors: Set<ValidationError>


    public init(framingMode: FramingMode,
                maxOutstandingLTFrameCount: UInt8,
                maxInfoLength: UInt16,
                maxInfoLength256: Bool,
                fixedFieldLTAndLAFrames: Bool,
                validationErrors: Set<ValidationError>) {

        self.framingMode = framingMode
        self.maxOutstandingLTFrameCount = maxOutstandingLTFrameCount
        self.maxInfoLength = maxInfoLength
        self.maxInfoLength256 = maxInfoLength256
        self.fixedFieldLTAndLAFrames = fixedFieldLTAndLAFrames
        self.validationErrors = validationErrors
    }

    // data without header length and type field
    public init(data: Data) throws {

        guard data.count >= 22 else {
            throw DecodingError.invalidSize
        }

        // decode and check framing mode
        let framingModeOffset: Int = 11
        let framingModeCode: UInt8 = data[data.startIndex.advanced(by: framingModeOffset)]
        guard let framingMode = FramingMode(rawValue: framingModeCode) else {
            throw DecodingError.invalidFramingMode
        }

        // decode maximum number outstanding LT frames
        let maxOutstandingLTFrameCountOffset: Int = 14
        let maxOutstandingLTFrameCount: UInt8 =
            data[data.startIndex.advanced(by: maxOutstandingLTFrameCountOffset)]

        // decode maximum information length
        let maxInfoLengthOffset: Int = 17
        let maxInfoLengthStart: Int =
            data.startIndex.advanced(by: maxInfoLengthOffset)
        let maxInfoLengthEnd: Int =
            maxInfoLengthStart.advanced(by: 2)
        let maxInfoLengthData: Data =
            data.subdata(in: maxInfoLengthStart..<maxInfoLengthEnd)
        guard let maxInfoLength = UInt16(littleEndianData: maxInfoLengthData) else {
            throw DecodingError.invalidMaxInfoLength
        }

        // decode data phase optimization
        let dataPhaseOptimizationOffset: Int = 21
        let dataPhaseOptimization: UInt8 =
            data[data.startIndex.advanced(by: dataPhaseOptimizationOffset)]
        let maxInfoLength256: Bool =
            dataPhaseOptimization & 0b00000001 == 0b01
        let fixedFieldLTAndLAFrames: Bool =
            dataPhaseOptimization & 0b00000010 == 0b10

        let validationErrors = MNPLinkRequestPacket.validate(data: data)

        self.init(framingMode: framingMode,
                  maxOutstandingLTFrameCount: maxOutstandingLTFrameCount,
                  maxInfoLength: maxInfoLength,
                  maxInfoLength256: maxInfoLength256,
                  fixedFieldLTAndLAFrames: fixedFieldLTAndLAFrames,
                  validationErrors: validationErrors)
    }

    private static func validate(data: Data) -> Set<ValidationError> {
        var errors: Set<ValidationError> = Set()

        // check constant parameter 1
        let constantParameter1Start = data.startIndex
        let constantParameter1End = constantParameter1Start.advanced(by: 1)
        let constantParameter1Range: Range<Data.Index> =
            constantParameter1Start..<constantParameter1End

        if data.subdata(in: constantParameter1Range)
            != MNPLinkRequestPacket.constantParameter1 {

            errors.insert(.invalidConstantParameter1)
        }

        // check constant parameter 2
        let constantParameter2Start = data.startIndex.advanced(by: 1)
        let constantParameter2End =
            constantParameter2Start
                .advanced(by: MNPLinkRequestPacket.constantParameter2.count)
        let constantParameter2Range: Range<Data.Index> =
            constantParameter2Start..<constantParameter2End

        if data.subdata(in: constantParameter2Range)
            != MNPLinkRequestPacket.constantParameter2 {

            errors.insert(.invalidConstantParameter2)
        }

        return errors
    }

    public func encode() -> Data {
        var encoded = Data()
        encoded.append(MNPPacketType.LR.rawValue)
        encoded.append(MNPLinkRequestPacket.constantParameter1)
        encoded.append(MNPLinkRequestPacket.constantParameter2)
        encoded.append(contentsOf: [0x2, 0x1, framingMode.rawValue])
        encoded.append(contentsOf: [0x3, 0x1, maxOutstandingLTFrameCount])
        encoded.append(contentsOf: [0x4, 0x2])
        // TODO: verify encoding
        encoded.append(maxInfoLength.littleEndianData)
        var dataPhaseOptimization: UInt8 = 0
        if maxInfoLength256 {
            dataPhaseOptimization |= 0b1
        }
        if fixedFieldLTAndLAFrames {
            dataPhaseOptimization |= 0b10
        }
        encoded.append(contentsOf: [0x8, 0x1, dataPhaseOptimization])

        // prepend length
        encoded.insert(UInt8(encoded.count), at: 0)

        return encoded
    }
}
