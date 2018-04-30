
import Foundation
import NSOF


public final class DockConnectionLayer {

    public enum State {
        case idle
        case initiatedDocking
        case sentDesktopInfo
        case sentWhichIcons
        case sentSetTimeout
        case connected
        case keyboardPassthrough
        case backingUp
        case disconnected
    }

    public enum Error: Swift.Error {
        case sendingWhichIconsFailed
        case missingNewtonKey
        case newtonKeyEnryptionKeyFailed
        case notConnected
    }

    private static let timeout: UInt32 = 60

    private static let desktopKey =
        Data(bytes: [0x64, 0x23, 0xef, 0x02, 0xfb, 0xcd, 0xc5, 0xa5])

    private static let desktopApps: NewtonPlainArray =
        [
            ["id": 2 as NewtonInteger,
             "name": "Newton Connection Utilities" as NewtonString,
             "version": 1 as NewtonInteger]
            as NewtonFrame
        ]

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

    public let keyboardPassthroughLayer = DockKeyboardPassthroughLayer()
    public let backupLayer = DockBackupLayer()

    public init() throws {
        des = try DES(keyBytes: DockConnectionLayer.desKey)
        keyboardPassthroughLayer.connectionLayer = self
        backupLayer.connectionLayer = self
    }

    public func read(packet: DecodableDockPacket) throws {

        print("XXX \(packet)")

        if packet is DisconnectPacket {
            state = .disconnected
            keyboardPassthroughLayer.handleDisconnect()
            backupLayer.handleDisconnect()
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
                                          allowSelectiveSync: false,
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
                guard resultPacket.error == .ok else {
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
                try keyboardPassthroughLayer.handleRequest()
                state = .keyboardPassthrough
            case is RequestToSyncPacket:
                try backupLayer.handleRequest()
                state = .backingUp
            default:
                break
            }
        case .keyboardPassthrough:
            try keyboardPassthroughLayer.read(packet: packet)
        case .backingUp:
            try backupLayer.read(packet: packet)
        case .disconnected:
            break
        }
    }

    internal func write(packet: EncodableDockPacket) throws {
        try onWrite?(packet)
    }

    public func startKeyboardPassthrough() throws {
        if state == .keyboardPassthrough {
            return
        }

        guard state == .connected else {
            throw Error.notConnected
        }

        try keyboardPassthroughLayer.start()
        state = .keyboardPassthrough
    }

    public func startBackup() throws {
        if state == .backingUp {
            return
        }

        guard state == .connected else {
            throw Error.notConnected
        }

        try backupLayer.start()
        state = .backingUp
    }

    internal func startDesktopControl() throws {
        try write(packet: DesktopInControlPacket())
    }

    internal func completeOperation() throws {
        try write(packet: OperationDonePacket())
        state = .connected
    }

    internal func acknowledgeOperationCanceled() throws {
        try write(packet: OperationCanceledAcknowledgementPacket())
    }
}
