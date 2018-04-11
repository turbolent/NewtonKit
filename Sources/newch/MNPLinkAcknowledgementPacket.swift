
import Foundation

// MNP / V.42 error correction T-REC-V.42-199303, Annex A

// TABLE A.3b/V.42: Link acknowledgement header-field parameters (optimized data phase)

public struct MNPLinkAcknowledgementPacket: MNPPacket {

    // A.6.4.2.1
    // Fixed parameter 0 - Length indication
    // The value of the length indication shall be [...] 3 in
    // an optimized data phase (see Table A.3b).

    // A.6.4.2.5 Fixed format for variable parameters 1 and 2 (optimized data phase)
    // When the fixed format LA frame facility is in effect during an optimized data phase,
    // the receive sequence number and the receive credit number are included in the fixed
    // part of the frame header field.
    //
    // The received sequence number value octet is fixed parameter 2.
    // The received credit number value octet is fixed parameter 3.

    public let receivedSequenceNumber: UInt8
    public let receivedCreditNumber: UInt8

    public init(data: Data) throws {
        let receivedSequenceNumberIndex = data.startIndex
        receivedSequenceNumber = data[receivedSequenceNumberIndex]

        let receivedCreditNumberIndex = data.startIndex.advanced(by: 1)
        receivedCreditNumber = data[receivedCreditNumberIndex]
    }

    public func encode() -> Data {
        return Data(bytes: [3, receivedSequenceNumber, receivedCreditNumber])
    }
}
