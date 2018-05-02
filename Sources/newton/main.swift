import Foundation
import Dispatch
import NewtonKit
import MNP
import NewtonDock
import NewtonSerialPort


let debugMNP = false

guard CommandLine.arguments.count > 1 else {
    fatalError("Missing path to serial port")
}

let path = CommandLine.arguments[1]
let serialPort = try NewtonSerialPort(path: path)

let group = DispatchGroup()
group.enter()

let mnpPacketLayer = MNPPacketLayer()
let mnpConnectionLayer = MNPConnectionLayer()
let dockPacketLayer = DockPacketLayer()
let dockConnectionLayer = try DockConnectionLayer()

// Configure read pipeline

serialPort.onRead = { data in
    try mnpPacketLayer.read(data: data)
}

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

mnpConnectionLayer.onRead = { data in
    try dockPacketLayer.read(data: data)
}

dockPacketLayer.onRead = { packet in
    try dockConnectionLayer.read(packet: packet)
}


// Configure write pipeline

dockConnectionLayer.onWrite = { packet in
    let data = try dockPacketLayer.write(packet: packet)
    try mnpConnectionLayer.write(data: data)
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
    try? serialPort.write(data: framed)
}


// Command prompt

let commandPrompt = CommandPrompt(dockConnectionLayer: dockConnectionLayer)
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
        exit(0)
    default:
        commandPrompt.handleDockConnectionState(state: state)
    }
}


// Start connection

try serialPort.open()
try serialPort.startReading()

defer {
    try? serialPort.close()
}

print("Connecting ...")

group.wait()


