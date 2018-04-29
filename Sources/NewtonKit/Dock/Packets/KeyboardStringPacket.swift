
import Foundation


public struct KeyboardStringPacket: EncodableDockPacket {

    public static let command: DockCommand = .keyboardString

    public let string: String

    public init(string: String) {
        self.string = string
    }

    public func encode() -> Data? {
        var data = string.data(using: .utf16BigEndian)!
        data.append(contentsOf: [0, 0])
        return data
    }
}
