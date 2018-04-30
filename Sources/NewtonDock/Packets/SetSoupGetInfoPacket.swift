
import Foundation


public struct SetSoupGetInfoPacket: EncodableDockPacket {

    public static let command: DockCommand = .setSoupGetInfo

    public let name: String

    public init(name: String) {
        self.name = name
    }

    public func encode() -> Data? {
        var data = name.data(using: .utf16BigEndian)!
        data.append(contentsOf: [0, 0])
        return data
    }
}
