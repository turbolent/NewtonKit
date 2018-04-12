
import Foundation

// MNP / V.42 error correction T-REC-V.42-199303, Annex A

public class MNPConnectionLayer {

    public enum ReadError: Error {
        case closed
    }

    public enum State {
        case idle
        case establishmentPhase
        case dataPhase
        case closed
    }

    public var onStateChange: ((State, State) -> Void)?

    private var state: State = .idle {
        didSet {
            onStateChange?(oldValue, state)
        }
    }

    public var onWrite: ((MNPPacket) -> Void)?
    public var onClose: ((MNPLinkDisconnectPacket.Reason?) -> Void)?

    private var linkResponse: MNPLinkRequestPacket?
    private var resentLinkResponse = false

    public init() {}

    public func write(packet: MNPPacket) {
        // TODO:
        onWrite?(packet)
    }

    // A.7.1 Protocol establishment phase procedures
    //
    // A.7.1.1 Initiating the establishment procedure
    //
    // The protocol establishment phase begins after a physical connection is established.
    // The originating DCE's error-correcting entity (the initiator) begins the procedures
    // of the protocol establishment phase. The answering DCE's error-correcting entity
    // (the responder) shall be ready to respond to protocol messages immediately after
    // the physical connection is established.

    public func read(packet: MNPPacket, handler: (Data) -> Void) throws {

        guard state != .closed else {
            throw ReadError.closed
        }

        // A.7.2 Disconnect phase procedures
        //
        // The LD frame is used to terminate a connection between two error-correcting entities.
        // When an LD frame is received by an error-correcting entity, the entity shall terminate
        // all protocol procedures and terminate the physical connection.

        if packet is MNPLinkDisconnectPacket {
            close()
            return
        }

        switch state {

        // A.7.1.3 Responder procedure
        //
        // The responder shall begin a connection establishment attempt by starting timer T401.
        // When an LR is received, the responder performs parameter negotiation (see A.7.1.5)
        // to determine the parameter values which will characterize the error-corrected connection.

        // TODO: start T401 timer waiting for LA, resend LR response if LA was not received

        case .idle:
            if let linkRequest = packet as? MNPLinkRequestPacket {
                state = .establishmentPhase
                handle(linkRequest: linkRequest)
            }

        // [...] When an acknowledgement LA is received, the responder enters the
        // data phase.
        //
        // The responder shall resend the response LR if
        // a) timer T401 expires while waiting for the LA response;
        // b) a protocol message arrives with an incorrect frame check sequence; or
        // c) another LR arrives.
        //
        // After resending the response LR, the responder restarts timer T401 and waits for a reply.
        // If the timer T401 again expires or if another protocol message arrives with an invalid
        // frame check sequence, the responder rejects the connection establishment.

        // TODO: handle invalid FCS: allow in packet layer, validate and handle here

        case .establishmentPhase:
            switch packet {
            case is MNPLinkAcknowledgementPacket:
                state = .dataPhase
            case is MNPLinkRequestPacket:
                if resentLinkResponse {
                    disconnect(reason: .protocolEstablishmentPhaseError)
                } else if let linkResponse = linkResponse {
                    // TODO: restart T401 timer waiting for LA
                    write(packet: linkResponse)
                    resentLinkResponse = true
                }
            default:

                // A.7.2.3 Protocol errors
                //
                // If the error-correcting entity receives unexpected protocol messages
                // or no response from the remote error-correcting entity, the local
                // entity will release the connection by sending an LD to terminate
                // the error-corrected connection. After sending the LD, the error-correcting
                // entity shall terminate the physical connection.

                disconnect(reason: .protocolEstablishmentPhaseError)
            }

        // A.7.3 Data phase procedures
        //
        // The data phase is entered once the physical connection is established and the protocol
        // establishment phase is completed. The procedures that apply to the transmission of user
        // data frames and acknowledgements during the information phase are described below.
        //
        // The LT and LA frames are used to transfer user data across an error-corrected connection.

        case .dataPhase:
            // TODO:
            fatalError()

        case .closed:
            break

        // TODO: reset self.linkResponse when back in idle

        }
    }

    // A.7.2.1 User-initiated disconnect
    //
    // At the end of user data transfer, the user may initiate disconnection of the
    // error-corrected connection. The interface between the user and the error-correcting
    // entity is beyond the scope of this Recommendation.
    //
    // A user-initiated disconnect may cause the error-correcting entity to send an LD
    // to terminate the error-corrected connection. After sending the LD or immediately
    // if the LD is not sent, the error-correcting entity shall terminate the physical
    // connection. It is recommended that the LD frame not be sent in order to promote
    // proper interworking with the installed base of error-correcting DCEs.

    func disconnect(reason: MNPLinkDisconnectPacket.Reason = .userInitiatedDisconnect) {
        write(packet: MNPLinkDisconnectPacket(reason: reason))
        close(reason: reason)
    }

    // no reason indicates a LD packet was received
    private func close(reason: MNPLinkDisconnectPacket.Reason? = nil) {
        // TODO: stop timers, etc.

        state = .closed
        onClose?(reason)
    }

    // A.7.1.3 Responder procedure
    //
    // [...]
    //
    // If negotiation is successful, the responder transmits an LR to the initiator and starts
    // its timer T401 in order to determine when too much time has elapsed waiting for an
    // acknowledgement. [...]
    //
    // A.7.1.4 Establishment rejection
    //
    // If the responder
    // a) receives an LR with parameters that the responder is not prepared to accept; or
    // [...]
    // then the responder shall enter the disconnect phase.
    //
    // [...]
    //
    // A.7.1.5 Parameter negotiation
    // The error-correcting entity examines the parameters and parameter values of the LR it
    // receives and compares them to its internal parameters. The negotiation rules are used
    // to resolve parameter differences. If the negotiation rules can not resolve the parameter
    // differences, then negotiation fails.
    //
    // A.7.1.5.1 Constant parameter 1
    //
    // Fixed parameter 1 shall always be of value 2. If another value is used, negotiation fails.
    //
    // A.7.1.5.2 Constant parameter 2
    // This parameter must always be present. The negotiation rule accepts any value for
    // constant parameter 2 and always produces the constant parameter value (see A.6.4.1.3)
    // as a result.
    //
    // A.7.1.5.3 Framing mode
    //
    // The negotiation rule selects the lower of the two values.
    //
    // A.7.1.5.6 Unknown parameters
    //
    // During negotiation, the responder shall ignore all unknown parameters.
    // When the responder sends its response LR, it includes only those parameters which it both
    // received and understood.

    private func handle(linkRequest: MNPLinkRequestPacket) {

        // ensure constant parameter 1 is correct.
        guard !linkRequest.validationErrors.contains(.invalidConstantParameter1) else {
            disconnect(reason: .unexpectedLRConstantParameter1)
            return
        }

        // - we only support start-stop, octet-oriented framing, and
        // - we only support optimized data phase frames
        //   (LT and LA frames have fixed fields)
        guard
            linkRequest.framingMode == .startStopOctetOriented,
            linkRequest.fixedFieldLTAndLAFrames
        else {
            disconnect(reason: .incompatibleOrUnknownLRParameterValue)
            return
        }

        // create a new packet, to ensure correct constant parameters are encoded
        let linkResponse = MNPLinkRequestPacket(
            framingMode: linkRequest.framingMode,
            maxOutstandingLTFrameCount: linkRequest.maxOutstandingLTFrameCount,
            maxInfoLength: linkRequest.maxInfoLength,
            maxInfoLength256: linkRequest.maxInfoLength256,
            fixedFieldLTAndLAFrames: linkRequest.fixedFieldLTAndLAFrames
        )

        self.linkResponse = linkResponse

        write(packet: linkResponse)
    }
}
