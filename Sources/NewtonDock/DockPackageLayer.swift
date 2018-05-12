
import Foundation
import NSOF


public class DockPackageLayer {

    public enum Error: Swift.Error {
        case notConnected
        case active
    }

    private enum State {
        case inactive
        case requestedInstall(package: Data)
        case loadingPackage
    }

    public var onResult: ((_ successful: Bool) -> Void)?

    internal weak var connectionLayer: DockConnectionLayer!

    private var state: State = .inactive

    private func write(packet: EncodableDockPacket) throws {
        try connectionLayer.write(packet: packet)
    }

    internal func start(package: Data) throws {

        guard case .inactive = state else {
            throw Error.active
        }

        guard connectionLayer.state != .loadingPackage else {
            throw Error.active
        }

        guard connectionLayer.state == .connected else {
            throw Error.notConnected
        }

        try connectionLayer.startDesktopControl()
        try write(packet: RequestToInstallPacket())
        state = .requestedInstall(package: package)
    }

    internal func handleDisconnect() {
        state = .inactive
    }

    private func sendError() throws {
        try connectionLayer.sendError()
        state = .inactive
    }

    public func read(packet: DecodableDockPacket) throws {

        if packet is OperationCanceledPacket {
            try connectionLayer.acknowledgeOperationCanceled()
            state = .inactive
            return
        }

        switch state {
        case .inactive:
            break
        case .requestedInstall(let package):
            guard
                let resultPacket = packet as? ResultPacket,
                resultPacket.error == .ok
            else {
                try sendError()
                return
            }

            try write(packet: LoadPackagePacket(package: package))
            state = .loadingPackage

        case .loadingPackage:

            guard
                let resultPacket = packet as? ResultPacket
            else {
                try sendError()
                return
            }

            onResult?(resultPacket.error == .ok)

            try connectionLayer.completeOperation()
            state = .inactive
        }
    }
}
