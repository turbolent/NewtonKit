
import Foundation

// MNP / V.42 error correction T-REC-V.42-199303, Annex A

public class MNPConnectionLayer {

    public enum Error: Swift.Error {
        case closed
        case invalidEstablishmentPhaseReceiveSequenceNumber
        case invalidLinkTransferDataCount
        case noSendCredit
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
    public var onRead: ((Data) -> Void)?
    public var onClose: ((MNPLinkDisconnectPacket.Reason?) -> Void)?

    private var linkResponse: MNPLinkRequestPacket?
    private var resentLinkResponse = false


    // A.7.5.6 Maximum number of octets in an information field (N401)
    //
    // The value of N401 shall indicate the maximum number of octets
    // in the information field, excluding DLE octets (in start- stop,
    // octet-oriented framing mode) [...] inserted for transparency,
    // that an error- correcting entity is willing to accept from the
    // correspondent entity.
    //
    // The value of N401 shall be determined during the protocol
    // establishment phase by LR variable parameter 4 (see A.6.4.1.7).

    private var maxInfoLength: UInt16 = 0


    // A.7.5.7 Maximum number of outstanding LT frames (k)
    //
    // The value of k shall indicate the maximum number of sequentially
    // numbered LT frames that the error-correcting entity may have
    // outstanding (i.e. unacknowledged).
    //
    // The value of k shall be determined during the protocol establishment
    // phase by LR variable parameter 3 (see A.6.4.1.6). T
    // he value of k shall never exceed 255.

    private var maxOutstandingLTFrameCount: UInt8 = 0


    // State variables

    // A.6.3.1 Modulus
    //
    // [...] The modulus is 256 [...]

    // A.6.3.2 Send state variable V(S)
    //
    // The send state variable V(S) denotes the sequence number of the next
    // in-sequence LT frame to be transmitted. V(S) can take on the values 0
    // through modulus minus 1. [...]

    private var sendState: UInt8 = 0

    private func incrementSendState() {
        sendState = sendState &+ 1
    }


    // A.6.3.4 Receive state variable V(R)
    //
    // The receive state variable V(R) denotes the sequence number of the next
    // in-sequence LT frame expected to be received. V(R) can take on the
    // values 0 through modulus minus 1. [...]

    private var receiveState: UInt8 = 0

    private func incrementReceiveState() {
        receiveState = receiveState &+ 1
    }


    // A.6.3.10 Receive credit state variable R(k)
    //
    // The receive credit state variable R(k) denotes the number of LT frames
    // the receiver is able to receive. [...]

    private var receiveCredit: UInt8 = 0


    // A.6.3.12 Send credit state variable S(k)
    //
    // The send credit state variable S(k) denotes the number of LT frames
    // the sender is able to transmit without receiving additional credit
    // from the receiver. [...]

    private var sendCredit: UInt8 = 0

    private func decrementSendCredit() {
        guard sendCredit > 0 else {
            return
        }
        sendCredit -= 1
    }


    // number of outstanding LT frames /
    // number of still unacknowledged LT frames in transit

    private var unacknowledgedTransferPacketCount: UInt8 = 0


    public init() {}


    // A.7.1 Protocol establishment phase procedures
    //
    // A.7.1.1 Initiating the establishment procedure
    //
    // The protocol establishment phase begins after a physical connection is established.
    // The originating DCE's error-correcting entity (the initiator) begins the procedures
    // of the protocol establishment phase. The answering DCE's error-correcting entity
    // (the responder) shall be ready to respond to protocol messages immediately after
    // the physical connection is established.

    public func read(packet: MNPPacket) throws {

        guard state != .closed else {
            throw Error.closed
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
                handleIdle(linkRequest: linkRequest)
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
            case let acknowledgementPacket as MNPLinkAcknowledgementPacket:

                state = .dataPhase

                try handleEstablishmentPhase(linkAcknowledgement: acknowledgementPacket)

                // A.7.3.3 Sending of an LA frame
                //
                // [...]
                //
                // Timer T404 shall be started when an error-correcting entity enters the data phase.

                // TODO: start timer T404

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
            switch packet {

            case let linkTransfer as MNPLinkTransferPacket:
                try handleDataPhase(linkTransfer: linkTransfer)

            case let linkAcknowledgement as MNPLinkAcknowledgementPacket:
                try handleDataPhase(linkAcknowledgement: linkAcknowledgement)

            // A.7.3.2.1 Reception of invalid frames
            //
            // When an error-correcting entity receives an invalid frame (see A.5),
            // it shall discard this frame.

            default:
                break

            }

        case .closed:
            break

        // TODO: reset self.linkResponse when back in idle

        }
    }


    // A.7.1 Protocol establishment phase procedures
    //
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

    private func handleIdle(linkRequest: MNPLinkRequestPacket) {

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

        // A.7.5.6 Maximum number of octets in an information field (N401)
        //
        // [...]
        // The value of N401 shall be determined during the protocol
        // establishment phase by LR variable parameter 4 (see A.6.4.1.7).

        maxInfoLength = linkRequest.maxInfoLength256
            ? 256
            : linkRequest.maxInfoLength

        // A.7.5.7 Maximum number of outstanding LT frames (k)
        //
        // [...]
        // The value of k shall be determined during the protocol
        // establishment phase by LR variable parameter 3 (see A.6.4.1.6).

        maxOutstandingLTFrameCount =
            linkRequest.maxOutstandingLTFrameCount

        sendLinkResponse(linkRequest: linkRequest)
    }


    private func sendLinkResponse(linkRequest: MNPLinkRequestPacket) {
        // create a new packet, to ensure correct constant parameters are encoded
        let linkResponse = MNPLinkRequestPacket(
            framingMode: linkRequest.framingMode,
            maxOutstandingLTFrameCount: linkRequest.maxOutstandingLTFrameCount,
            maxInfoLength: linkRequest.maxInfoLength,
            maxInfoLength256: linkRequest.maxInfoLength256,
            fixedFieldLTAndLAFrames: linkRequest.fixedFieldLTAndLAFrames,
            validationErrors: Set()
        )

        self.linkResponse = linkResponse

        write(packet: linkResponse)
    }


    private func handleEstablishmentPhase(linkAcknowledgement: MNPLinkAcknowledgementPacket) throws {

        // A.6.4.2.3 Variable parameter 1 - Receive sequence number (non-optimized data phase)
        //
        // [...] The value used for the receive sequence number in the protocol establishment phase
        // confirming the LA shall be 0.

        guard linkAcknowledgement.receiveSequenceNumber == 0 else {
            throw Error.invalidEstablishmentPhaseReceiveSequenceNumber
        }

        // A.6.3.2 Send state variable V(S)
        //
        // Upon data phase initialization, V(S) is set to 1.

        sendState = 1

        // A.6.3.4 Receive state variable V(R)
        //
        // Upon data phase initialization, V(R) is set to 1.

        receiveState = 1

        // A.6.3.10 Receive credit state variable R(k)
        //
        // [...] k (the maximum number of outstanding LT frames). [...]
        // When the error-correcting entity enters the data phase,
        // R(k) is set equal to k.

        receiveCredit = maxOutstandingLTFrameCount

        // A.6.3.12 Send credit state variable S(k)
        //
        // [...] k (the maximum number of outstanding LT frames). [...]
        // Upon data phase initialization, S(k) is set to k.

        sendCredit = maxOutstandingLTFrameCount

        unacknowledgedTransferPacketCount = 0
    }

    // Data phase
    //
    //         ┌──────────┐                       ┌────────────┐
    //         │  Sender  │                       │  Receiver  │
    //         └──────────┘                       └────────────┘
    //               │                                   │
    //      send state  V(S): A
    //      send credit S(k): B                          │
    //                                LT
    //               ├───────────────────────────────────▶
    //                       send sequence N(S): A
    //               │                                   │
    //    send state  V(S): A + 1          receive state V(R): X = A + 1
    //    send credit S(k): B - 1          receive credit R(k): Y
    //
    //               │                LA                 │
    //               ◀────────────────────────────────────
    //               │  receive sequence N(R): Z = X - 1 │
    //                  receive credit N(k): Y
    //               │                                   │
    //    unack: A - Z
    //    send credit S(k): Y - unack                    │
    //
    //               │                                   │
    //

    // A.7.3.2 Receiving an LT frame
    //
    // When an error-correcting entity receives a valid LT frame whose send sequence
    // number N(S) is equal to the local receive state variable V(R),
    // the error-correcting entity will accept the information field of this frame
    // and increment by one, modulo 256, its receive state variable V(R).
    //
    // Reception of an LT frame will start timer T402 if timer T402 is not already running.
    //
    // Reception of an LT frame may also cause transmission of an acknowledgement (LA)
    // frame (see A.7.3.3).

    private func handleDataPhase(linkTransfer: MNPLinkTransferPacket) throws {

        // A.7.3.2.2 Reception of out-of-sequence LT frames
        //
        // When an error-correcting entity receives a valid LT frame whose send
        // sequence number N(S) is not equal to the current receive state variable V(R),
        // the error-correcting entity shall discard the information field of the LT frame
        // and transmit an LA frame as described in A.7.3.3.
        //
        // The first reception of an LT frame with N(S) = V(R) - 1, however, is ignored
        // and does not cause transmission of an LA frame.

        guard linkTransfer.sendSequenceNumber == receiveState else {

            // TODO: only send LA if necessary
            try sendLinkAcknowledgement()
            return
        }

        // A.7.3.2.3 Reception of LT frames without receive credit
        //
        // When an error-correcting entity receives a valid LT frame when the receive credit R(k) = 0,
        // the error-correcting entity shall discard the information field of the LT frame
        // and transmit an LA frame as described in A.7.3.3.

        guard receiveCredit > 0 else {
            try sendLinkAcknowledgement()
            return
        }

        incrementReceiveState()

        // TODO: start T402

        onRead?(linkTransfer.information)

        // NOTE: according to the spec we should be able to hold of acknowledging
        // every packet, but testing with a MP130/2.0 required it
        try sendLinkAcknowledgement()
    }


    // A.7.3.4 Receiving an LA frame
    //
    // When an LA frame is received, the receiving error-correcting entity will consider the N(R)
    // contained in this frame as an acknowledgement for all LT frames it has transmitted with
    // an N(S) up to and including the received N(R). Timer T401 will be stopped if no additional
    // LT frames remain unacknowledged, i.e. the received LA frame acknowledges all outstanding
    // LT frames. Timer T401 will be restarted if additional LT frames remain unacknowledged.
    //
    // An error-correcting entity that receives an LA frame uses the N(k) contained in the frame,
    // minus the number of still unacknowledged LT frames in transit, as the new S(k) value.

    private func handleDataPhase(linkAcknowledgement: MNPLinkAcknowledgementPacket) throws {

        unacknowledgedTransferPacketCount =
            sendState - linkAcknowledgement.receiveSequenceNumber

        if unacknowledgedTransferPacketCount > 0 {
            // TODO: restart timer T401
        } else {
            // TODO: stop timer T401
        }

        // TODO: subtract unacknowledgedPacketCount
        sendCredit =
            linkAcknowledgement.receiveCreditNumber - unacknowledgedTransferPacketCount
    }


    // A.7.3.3 Sending of an LA frame
    //
    // An error-correcting entity sends an LA frame to acknowledge successful reception
    // of one or more LT frames or to signal the correspondent entity of a condition which
    // may require retransmission of one or more LT frames. The LA frame also communicates
    // the receiverís ability to accept additional LT frames.
    //
    // [...]
    //
    // Timer T404 shall be restarted whenever an LA frame is sent.

    private func sendLinkAcknowledgement() throws {

        // A.6.3.5 Receive sequence number N(R)
        //
        // All LA frames contain N(R), the send sequence number of the last received LT frame.
        // At the time that an LA frame is designated for transmission, the value of N(R) is
        // set equal to the current value of the receive state variable V(R) - 1.
        //
        // N(R) indicates that the error-correcting entity transmitting the N(R) has received
        // correctly all LT frames numbered up to and including N(R).

        let receiveSequenceNumber = receiveState - 1

        // A.6.3.11 Receive credit number N(k)
        //
        // Only LA frames contains N(k). At the time that an LA frame is designated for transmission,
        // the value of N(k) is set equal to the value of the receive credit state variable R(k).
        // N(k) indicates that the error-correcting entity transmitting the N(k) can properly receive
        // LT frames numbered up to and including N(R) + N(k).

        let receiveCreditNumber = receiveCredit

        write(packet: MNPLinkAcknowledgementPacket(receiveSequenceNumber: receiveSequenceNumber,
                                                   receiveCreditNumber: receiveCreditNumber))

        // TODO: restart T404
    }

    // A.7.3.1 Sending an LT frame
    //
    // When an error-correcting entity has user data to transmit, the entity will
    // transmit an LT with an N(S) equal to its current send state variable V(S).
    // Each LT shall contain no more than N401 user octets in the information field.
    // At the end of transmission of the LT frame, the error-correcting entity will
    // increment, modulo 256, its send state variable V(S) by 1 and decrement S(k) by 1.
    //
    // If timer T401 is not running at the time of transmission of an LT frame,
    // it will be started. When k = 1, the timer is started after the error-correcting
    // entity completes LT frame transmission. When k > 1, the timer is started when the
    // error- correcting entity begins LT frame transmission.
    //
    // If S(k) = 0, the error-correcting entity will not transmit any LT frames
    // until S(k) is updated to a non-zero value through the receipt of an LA frame.

    private func sendLinkTransfer(data: Data) throws {

        guard data.count <= maxInfoLength else {
            throw Error.invalidLinkTransferDataCount
        }

        guard sendCredit > 0 else {
            throw Error.noSendCredit
        }

        // TODO: check maxOutstandingLTFrameCount rule

        // A.6.3.3 Send sequence number N(S)
        //
        // Only LT frames contain N(S), the send sequence number of transmitted LT frames.
        // At the time that an in-sequence LT frame is designated for transmission,
        // the value of N(S) is set equal to the value of the send state variable V(S).

        // A.6.3.2 Send state variable V(S)
        //
        // [...]
        // The value of V(S) is incremented by 1 with each successive LT frame transmission,
        // but cannot exceed N(R) of the last received LA frame by more than the maximum number
        // of outstanding LT frames (k).

        let sendSequenceNumber = sendState

        write(packet: MNPLinkTransferPacket(sendSequenceNumber: sendSequenceNumber,
                                            information: data))

        incrementSendState()
        decrementSendCredit()

        // TODO: start timer T401
    }

    public func write(data: Data) throws {
        for information in data.chunk(n: Int(maxInfoLength)) {
            try sendLinkTransfer(data: information)
        }
    }

    private func write(packet: MNPPacket) {

        // TODO:
        onWrite?(packet)
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

    public func disconnect() {
        disconnect(reason: .userInitiatedDisconnect)
    }

    private func disconnect(reason: MNPLinkDisconnectPacket.Reason) {
        write(packet: MNPLinkDisconnectPacket(reason: reason))
        close(reason: reason)
    }

    // no reason indicates a LD packet was received
    private func close(reason: MNPLinkDisconnectPacket.Reason? = nil) {
        // TODO: stop timers, etc.

        state = .closed
        onClose?(reason)
    }
}
