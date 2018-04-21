import Foundation
import newch

let debugMNP = true

guard CommandLine.arguments.count > 1 else {
    fatalError("Missing path to serial port")
}
let path = CommandLine.arguments[1]
let serialPort = try SerialPort(path: path)

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


// Start connection

try serialPort.open()
try serialPort.startReading()

defer {
    try? serialPort.close()
}

group.wait()
