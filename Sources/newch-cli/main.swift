import Foundation
import newch


let packetLayer = MNPPacketLayer()

let group = DispatchGroup()
group.enter()

// let path = "/dev/ttyUSB0"
let path = "/dev/cu.usbserial-AL02AUFM"

let serialPort = try SerialPort(path: path)

serialPort.onCancel = {
    group.leave()
}

serialPort.onData = { data in
    try? packetLayer.read(data: data) { packet in
        if packet is MNPLinkRequestPacket {
            let framed = packetLayer.write(data: packet.encode())
            try? serialPort.write(data: framed)
        }
    }
}

try serialPort.open()
try serialPort.startReading()

defer {
    try? serialPort.close()
}

group.wait()

