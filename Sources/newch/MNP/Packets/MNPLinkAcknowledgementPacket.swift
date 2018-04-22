
import Foundation

// MNP / V.42 error correction T-REC-V.42-199303, Annex A

// A.6.4.2 Link acknowledgement (LA) frame
//
// The link acknowledgement (LA) frame is used to confirm the completion of the protocol
// establishment phase of the alternative error-correcting procedure. The confirming LA
// is sent by the error-correcting entity that sent the initiating LR frame.
//
// Upon sending or receiving the confirming LA of the connection-establishment,
// three-message exchange, the error-correcting entity enters the data phase.

// TABLE A.3b/V.42: Link acknowledgement header-field parameters (optimized data phase)

public struct MNPLinkAcknowledgementPacket: MNPPacket {

    public enum DecodingError: Error {
        case invalidSize
    }


    // A.6.4.2.3 Variable parameter 1 -
    // Receive sequence number (non-optimized data phase)
    //
    // The receive sequence number parameter contains the value of the
    // receive number, N(R), of the last correctly received LT frame.
    // The value used for the receive sequence number in the protocol
    // establishment phase confirming the LA shall be 0.

    public let receiveSequenceNumber: UInt8


    // A.6.4.2.4 Variable parameter 2 -
    // Receive credit number (non-optimized data phase)
    //
    // The receive credit number parameter contains the value of the
    // maximum number of LT frames that can be sent by an error-correcting
    // entity before it must suspend sending LT frames and wait for an
    // acknowledgement.
    //
    // The value used for the receive credit for the confirming LA is
    // the value received as the receive credit in the response LR.

    // A.6.3.11 Receive credit number N(k)
    //
    // Only LA frames contains N(k). [...]

    public let receiveCreditNumber: UInt8


    public init(receiveSequenceNumber: UInt8,
                receiveCreditNumber: UInt8) {

        self.receiveSequenceNumber = receiveSequenceNumber
        self.receiveCreditNumber = receiveCreditNumber
    }


    // A.6.4.2.5 Fixed format for variable parameters 1 and 2 (optimized data phase)
    //
    // When the fixed format LA frame facility is in effect during an optimized data phase,
    // the receive sequence number and the receive credit number are included in the fixed
    // part of the frame header field.
    //
    // The received sequence number value octet is fixed parameter 2.
    // The received credit number value octet is fixed parameter 3.

    // A.6.4.2.1
    // Fixed parameter 0 - Length indication
    //
    // The value of the length indication shall be [...] 3 in
    // an optimized data phase (see Table A.3b).

    // data without header length and type field
    public init(data: Data) throws {
        guard data.count >= 2 else {
            throw DecodingError.invalidSize
        }

        let receiveSequenceNumberIndex = data.startIndex
        let receiveCreditNumberIndex = receiveSequenceNumberIndex.advanced(by: 1)

        self.init(receiveSequenceNumber: data[receiveSequenceNumberIndex],
                  receiveCreditNumber: data[receiveCreditNumberIndex])
    }

    public func encode() -> Data {
        return Data(bytes: [
            3,
            MNPPacketType.LA.rawValue,
            receiveSequenceNumber,
            receiveCreditNumber
        ])
    }
}
