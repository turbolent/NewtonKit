
import Foundation


public struct LoadPackagePacket: EncodableDockPacket {

    public static let command: DockCommand = .loadPackage

    public let package: Data

    public init(package: Data) {
        self.package = package
    }

    public func encode() -> Data? {
        var data = package

        let length = UInt32(data.count)
        let roundedLength = DockPacketLayer.roundToBoundary(length: length)
        let padding = Int(roundedLength - length)
        if padding != 0 {
            data.append(Data(repeating: 0, count: padding))
        }
        return data
    }
}
