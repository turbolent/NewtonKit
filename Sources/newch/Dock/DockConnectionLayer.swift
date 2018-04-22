
import Foundation

public class DockConnectionLayer {

    public enum State {
        case idle
        case initiatedDocking
        case sentDesktopInfo
        case sentWhichIcons
        case sentSetTimeout
        case connected
        case sentKeyboardPassthrough
        case keyboardPassthrough
        case initiatedSync
        case disconnected
    }

    public enum Error: Swift.Error {
        case sendingWhichIconsFailed
        case missingNewtonKey
        case newtonKeyEnryptionKeyFailed
        case notConnected
        case notInKeyboardPassthrough
    }

    private static let timeout: UInt32 = 60

    private static let desktopKey =
        Data(bytes: [0x64, 0x23, 0xef, 0x02, 0xfb, 0xcd, 0xc5, 0xa5])

    private static let desktopApps =
        Data(bytes: [
            0x02, 0x05, 0x01, 0x06, 0x03, 0x07, 0x02, 0x69,
            0x64, 0x07, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x07,
            0x07, 0x76, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e,
            0x00, 0x08, 0x08, 0x38, 0x00, 0x4e, 0x00, 0x65,
            0x00, 0x77, 0x00, 0x74, 0x00, 0x6f, 0x00, 0x6e,
            0x00, 0x20, 0x00, 0x43, 0x00, 0x6f, 0x00, 0x6e,
            0x00, 0x6e, 0x00, 0x65, 0x00, 0x63, 0x00, 0x74,
            0x00, 0x69, 0x00, 0x6f, 0x00, 0x6e, 0x00, 0x20,
            0x00, 0x55, 0x00, 0x74, 0x00, 0x69, 0x00, 0x6c,
            0x00, 0x69, 0x00, 0x74, 0x00, 0x69, 0x00, 0x65,
            0x00, 0x73, 0x00, 0x00, 0x00, 0x04
        ])

    private static let desKey: [UInt8] =
        [0xe4, 0x0f, 0x7e, 0x9f, 0x0a, 0x36, 0x2c, 0xfa]

    public var onStateChange: ((State, State) -> Void)?
    public var onDisconnect: (() -> Void)?
    public var onWrite: ((EncodableDockPacket) throws -> Void)?

    public private(set) var state: State = .idle {
        didSet {
            onStateChange?(oldValue, state)
        }
    }

    private var des: DES
    private var newtonKey: Data?

    public init() throws {
        des = try DES(keyBytes: DockConnectionLayer.desKey)
    }

    public func read(packet: DecodableDockPacket) throws {


        if packet is DisconnectPacket {
            state = .disconnected
            onDisconnect?()
            return
        }

        switch state {
        case .idle:
            if packet is RequestToDockPacket {
                try write(packet: InitiateDockingPacket(sessionType: .noSession))
                state = .initiatedDocking
            }
        case .initiatedDocking:
            if packet is NewtonNamePacket {
                let packet =
                    try DesktopInfoPacket(protocolVersion: 10,
                                          desktopType: .macintosh,
                                          encryptedKey: DockConnectionLayer.desktopKey,
                                          sessionType: .settingUpSession,
                                          allowSelectiveSync: true,
                                          desktopApps: DockConnectionLayer.desktopApps)
                try write(packet: packet)
                state = .sentDesktopInfo
            }
        case .sentDesktopInfo:
            if let newtonInfoPacket = packet as? NewtonInfoPacket {
                newtonKey = newtonInfoPacket.encryptedKey
                try write(packet: WhichIconsPacket(iconMask: .all))
                state = .sentWhichIcons
            }
        case .sentWhichIcons:
            if let resultPacket = packet as? ResultPacket {
                guard resultPacket.errorCode == 0 else {
                    throw Error.sendingWhichIconsFailed
                }
                try write(packet: SetTimeoutPacket(timeout: DockConnectionLayer.timeout))
                state = .sentSetTimeout
            }
        case .sentSetTimeout:
            if packet is PasswordPacket {
                guard let newtonKey = newtonKey else {
                    throw Error.missingNewtonKey
                }
                guard let encryptedKey = des.encrypt(source: newtonKey) else {
                    throw Error.newtonKeyEnryptionKeyFailed
                }
                try write(packet: PasswordPacket(encryptedKey: encryptedKey))
                state = .connected
            }
        case .connected:
            switch packet {
            case is OperationCanceledPacket:
                try write(packet: OperationCanceledAcknowledgementPacket())
                state = .connected
            case is StartKeyboardPassthroughPacket:
                try write(packet: StartKeyboardPassthroughPacket())
                state = .keyboardPassthrough
            case is RequestToSyncPacket:
                try write(packet: GetSyncOptionsPacket())
                state = .initiatedSync
            default:
                break
            }
        case .sentKeyboardPassthrough:
            if packet is StartKeyboardPassthroughPacket {
                state = .keyboardPassthrough
            }
        case .keyboardPassthrough:
            break
        case .initiatedSync:
            switch packet {
            case is SyncOptionsPacket:
                // request the time the current store was last backed up
                try write(packet: LastSyncTimePacket())
            case is CurrentTimePacket:
                // TODO:
                break
            case is OperationCanceledPacket:
                try write(packet: OperationCanceledAcknowledgementPacket())
                state = .connected
            default:
                break
            }
        case .disconnected:
            break
        }
    }

    private func write(packet: EncodableDockPacket) throws {
        try onWrite?(packet)
    }

    public func startDesktopControl() throws {
        try write(packet: DesktopInControlPacket())
    }

    public func startKeyboardPassthrough() throws {
        guard state == .connected else {
            throw Error.notConnected
        }

        try startDesktopControl()
        try write(packet: StartKeyboardPassthroughPacket())
        state = .sentKeyboardPassthrough
    }

    public func sendKeyboardCharacter(_ character: UInt16) throws {
        guard state == .keyboardPassthrough else {
            throw Error.notInKeyboardPassthrough
        }

        try write(packet: KeyboardCharPacket(character: character, state: 1))
    }

    public func sendKeyboardString(_ string: String) throws {
        guard state == .keyboardPassthrough else {
            throw Error.notInKeyboardPassthrough
        }

        try write(packet: KeyboardStringPacket(string: string))
    }

    public func stopKeyboardPassthrough() throws {
        if state == .connected {
            return
        }

        guard .keyboardPassthrough == state else {
            throw Error.notInKeyboardPassthrough
        }

        try stopDesktopControl()
        state = .connected
    }

    public func stopDesktopControl() throws {
        try write(packet: OperationDonePacket())
    }
}
