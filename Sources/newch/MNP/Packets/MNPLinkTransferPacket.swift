
import Foundation

// MNP / V.42 error correction T-REC-V.42-199303, Annex A

// A.6.6.1 Link transfer (LT) frame
//
// The function of the LT transfer (LT) frame is to transfer user data across
// the error-corrected connection in sequentially numbered information fields.
// The header-field parameters of the link transfer frame are shown in [...]
// Table A.6b.
//
// The information field shall contain one or more octets of user data up to
// the maximum information-field length negotiated during the protocol
// establishment phase. A null (zero octets) information field is not allowed.

// TABLE A.6b/V.42: Link transfer header-field parameters (optimized data phase)

public struct MNPLinkTransferPacket: MNPPacket {

    public enum DecodingError: Error {
        case invalidSize
    }


    // A.6.6.1.3 Variable parameter 1 –
    // Send sequence number parameter (non-optimized data phase)
    //
    // The send sequence number parameter defines the order of this frame and its
    // information field in the data-sequence space. At the time that an LT frame
    // is designated for transmission, the value of this parameter is set equal
    // to the send state variable V(S). The send state variable is initially 1,
    // and is incremented modulo 256 with each successive LT frame transmission.

    public let sendSequenceNumber: UInt8


    public let information: Data


    public init(sendSequenceNumber: UInt8,
                information: Data) {
        self.sendSequenceNumber = sendSequenceNumber
        self.information = information
    }


    // A.6.6.1.4 - Fixed format for variable parameter 1 (optimized data phase)
    //
    // When the fixed format LT frame facility is in effect during an
    // optimized data phase, the send sequence number is included in the fixed part
    // of the frame header field.
    //
    // The send sequence number value octet is fixed parameter 2.

    // data without header length and type field
    public init(data: Data) throws {
        guard data.count >= 1 else {
            throw DecodingError.invalidSize
        }

        let sendSequenceNumberIndex = data.startIndex
        let sendSequenceNumber = data[sendSequenceNumberIndex]
        let information = data.dropFirst()

        self.init(sendSequenceNumber: sendSequenceNumber,
                  information: information)
    }

    public func encode() -> Data {
        var result = Data(bytes: [
            2,
            MNPPacketType.LT.rawValue,
            sendSequenceNumber
        ])
        result.append(information)
        return result
    }
}
