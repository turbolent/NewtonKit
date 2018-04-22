
import Foundation

public struct KeyboardCharPacket: EncodableDockPacket {

    public static let command: DockCommand = .keyboardChar

    public let character: UInt16
    public let state: UInt16

    public init(character: UInt16, state: UInt16) {
        self.character = character
        self.state = state
    }

    public func encode() -> Data? {
        var data = Data()
        data.append(character.bigEndianData)
        data.append(state.bigEndianData)
        return data
    }
}

