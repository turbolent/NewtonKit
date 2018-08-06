import Foundation
import Dispatch
import NewtonKit
import MNP
import NewtonDock
import NewtonSerialPort
import NewtonServer

enum ConnectionType: String {
    case serial
    case tcp
}

guard CommandLine.arguments.count > 1 else {
    fatalError("Missing connection type: provide 'serial' or 'tcp'")
}

guard let connectionType = ConnectionType(rawValue: CommandLine.arguments[1]) else {
    fatalError("Invalid connection type: provide 'serial' or 'tcp'")
}

struct Connection {
    let configureRead: (@escaping (Data) throws -> Void) throws -> Void
    let write: (Data) throws -> Void
    let start: () throws -> Void
    let stop: () -> Void
}

let connection: Connection

let dockPacketLayer = DockPacketLayer()
let dockConnectionLayer = try DockConnectionLayer()


switch connectionType {
case .serial:

    guard CommandLine.arguments.count > 2 else {
        fatalError("Missing path to serial port")
    }

    let path = CommandLine.arguments[2]
    let serialPort = try NewtonSerialPort(path: path)

    serialPort.onCancel = { error in
        fatalError("Serial port encountered error: \(error)")
    }

    let mnpPacketLayer = MNPPacketLayer()
    let mnpConnectionLayer = MNPConnectionLayer()

    let debugMNP = false

    mnpPacketLayer.onRead = { packet in

        if debugMNP {
            switch packet {
            case let lt as MNPLinkTransferPacket:
                print(">>> LT: \(lt.sendSequenceNumber)\n\(lt.information.hexDump)\n")
            case let la as MNPLinkAcknowledgementPacket:
                print(">>> LA: \(la.receiveSequenceNumber)\n")
            default:
                break
            }
        }

        try mnpConnectionLayer.read(packet: packet)
    }

    serialPort.onRead = { data in
        try mnpPacketLayer.read(data: data)
    }

    mnpConnectionLayer.onWrite = { packet in

        if debugMNP {
            switch packet {
            case let lt as MNPLinkTransferPacket:
                print("<<< LT: \(lt.sendSequenceNumber)\n\(lt.information.hexDump)\n")
            case let la as MNPLinkAcknowledgementPacket:
                print("<<< LA: \(la.receiveSequenceNumber)\n")
            default:
                break
            }
        }

        let encoded = packet.encode()
        let framed = mnpPacketLayer.write(data: encoded)

        try serialPort.write(data: framed)

    }

    connection = Connection(
        configureRead: {
            mnpConnectionLayer.onRead = $0
        },
        write: {
            try mnpConnectionLayer.write(data: $0)
        },
        start: {
            try serialPort.open()
            try serialPort.startReading()
        },
        stop: {
            try? serialPort.close()
        }
    )
case .tcp:
    let server = NewtonServer()

    server.onConnect = {
        print("Connected from \($0)")
    }

    connection = Connection(
        configureRead: {
            server.onRead = $0
        },
        write: {
            try server.write(data: $0)
        },
        start: {
            try server.listen(port: 3679)
        },
        stop: {
            server.stopListening()
        }
    )
}

let group = DispatchGroup()
group.enter()


// Configure read pipeline

dockPacketLayer.onRead = { packet in
    try dockConnectionLayer.read(packet: packet)
}


// Configure write pipeline

dockConnectionLayer.onWrite = { packet in
    let data = try dockPacketLayer.write(packet: packet)

    try connection.write(data)

}


// Command prompt

let commandPrompt = try CommandPrompt(dockConnectionLayer: dockConnectionLayer)
dockConnectionLayer.onStateChange = { _, state in
    switch state {
    case .connected:
        if commandPrompt.started {
            commandPrompt.handleDockConnectionState(state: state)
        } else {
            print("Connected")
            DispatchQueue.global(qos: .userInteractive).async {
                try? commandPrompt.start()
            }
        }
    case .disconnected:
        print("Disconnected")
    default:
        commandPrompt.handleDockConnectionState(state: state)
    }
}


// Start connection

try connection.configureRead { data in
    try dockPacketLayer.read(data: data)
}

try connection.start()

defer {
    connection.stop()
}

print("Waiting for connection ...")

group.wait()
