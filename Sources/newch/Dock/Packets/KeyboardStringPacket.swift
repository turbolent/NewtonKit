
import Foundation


public struct KeyboardStringPacket: EncodableDockPacket {

    public static let command: DockCommand = .keyboardString

    public let string: String

    public init(string: String) {
        self.string = string
    }

    public func encode() -> Data? {
        var data = Data()
        for character in string.utf16 {
            data.append(UInt16(character).bigEndianData)
        }
        data.append(contentsOf: [0, 0])
        return data
    }
}

