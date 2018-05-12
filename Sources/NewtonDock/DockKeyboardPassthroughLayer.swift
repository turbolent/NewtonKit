
public class DockKeyboardPassthroughLayer {

    public enum Error: Swift.Error {
        case notConnected
        case notActive
    }

    private enum State {
        case inactive
        case sentKeyboardPassthrough
        case active
    }

    private var state: State = .inactive

    internal weak var connectionLayer: DockConnectionLayer!

    public func read(packet: DecodableDockPacket) throws {

        if packet is OperationCanceledPacket {
            try connectionLayer.acknowledgeOperationCanceled()
            state = .inactive
            return
        }

        // did the Newton acknowledged the start?
        if state == .sentKeyboardPassthrough
            && packet is StartKeyboardPassthroughPacket {

            state = .active
        }
    }

    private func write(packet: EncodableDockPacket) throws {
        try connectionLayer.write(packet: packet)
    }

    public func handleRequest() throws {
        // acknowledge start
        try write(packet: StartKeyboardPassthroughPacket())
        state = .active
    }

    internal func handleDisconnect() {
        state = .inactive
    }

    internal func start() throws {
        if state == .active || connectionLayer.state == .keyboardPassthrough  {
            return
        }

        guard connectionLayer.state == .connected else {
            throw Error.notConnected
        }

        try connectionLayer.startDesktopControl()
        try write(packet: StartKeyboardPassthroughPacket())
        state = .sentKeyboardPassthrough
    }
    
    public func sendCharacter(_ character: UInt16) throws {
        guard state == .active else {
            throw Error.notActive
        }

        try write(packet: KeyboardCharPacket(character: character, state: 1))
    }

    public func sendString(_ string: String) throws {
        guard state == .active else {
            throw Error.notActive
        }

        try write(packet: KeyboardStringPacket(string: string))
    }

    public func stop() throws {
        if connectionLayer.state == .connected {
            return
        }

        guard connectionLayer.state == .keyboardPassthrough else {
            throw Error.notActive
        }

        try connectionLayer.completeOperation()
        state = .inactive
    }
}
