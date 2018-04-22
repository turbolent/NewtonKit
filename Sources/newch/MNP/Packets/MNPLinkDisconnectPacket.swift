
import Foundation

// MNP / V.42 error correction T-REC-V.42-199303, Annex A

// A.6.5.1 Link disconnect (LD) frame
//
// The link disconnect (LD) frame is used to terminate operation
// of an active error-corrected connection, or to reject an attempt
// to establish an error-corrected connection.

// TABLE A.4/V.42: Link disconnect header-field parameters

public struct MNPLinkDisconnectPacket: MNPPacket {

    public enum DecodingError: Error {
        case invalidSize
        case invalidReason
    }

    
    // TABLE A.5/V.42: Link disconnect reason code

    public enum Reason: UInt8 {

        // NOTE: not specified in V.42, but only sensible value
        // for other protocol errors, as 4-254 are reserved,
        // and this code is also sent by an MP130/2.0
        case protocolError = 0

        // Protocol establishment phase error, LR expected but not received
        case protocolEstablishmentPhaseError = 1

        // LR constant parameter 1 contains an unexpected value
        case unexpectedLRConstantParameter1 = 2

        // LR received with incompatible or unknown parameter value
        case incompatibleOrUnknownLRParameterValue = 3

        case userInitiatedDisconnect = 255
    }


    // A.6.5.1.3 Variable parameter 1 - Reason code
    //
    // The reason-code parameter defines the reason for disconnection
    // when sent in an LD frame on an active error-corrected connection,
    // or the reason for failure to establish when sent in an LD frame
    // in response to a connection attempt.

    public let reason: Reason


    public init(reason: Reason) {
        self.reason = reason
    }
    
    // data without header length and type field
    public init(data: Data) throws {
        guard data.count >= 3 else {
            throw DecodingError.invalidSize
        }

        // decode maximum number outstanding LT frames
        let reasonOffset = 2
        let reasonCode = data[data.startIndex.advanced(by: reasonOffset)]
        guard let reason = Reason(rawValue: reasonCode) else {
            throw DecodingError.invalidReason
        }

        self.init(reason: reason)
    }

    public func encode() -> Data {
        return Data(bytes: [
            4,
            MNPPacketType.LD.rawValue,
            0x1, 0x1, reason.rawValue
        ])
    }
}

