
import Foundation

public class DockConnectionLayer {

    public enum State {
        case idle
        case initiatedDocking
        case sentDesktopInfo
        case sentWhichIcons
        case sentSetTimeout
        case connected
        case disconnected
    }

    public enum Error: Swift.Error {
        case sendingWhichIconsFailed
        case missingNewtonKey
        case newtonKeyEnryptionKeyFailed
    }

    private static let timeout: UInt32 = 60

    private static let desktopKey =
        Data(bytes: [0x64, 0x23, 0xef, 0x02, 0xfb, 0xcd, 0xc5, 0xa5])

    private static let desKey: [UInt8] =
        [0xe4, 0x0f, 0x7e, 0x9f, 0x0a, 0x36, 0x2c, 0xfa]

    public var onStateChange: ((State, State) -> Void)?
    public var onDisconnect: (() -> Void)?
    public var onWrite: ((EncodableDockPacket) throws -> Void)?

    private var state: State = .idle {
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
                                          allowSelectiveSync: true)
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
}
