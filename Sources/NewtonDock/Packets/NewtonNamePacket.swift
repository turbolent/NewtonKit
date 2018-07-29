
import Foundation


public struct NewtonNamePacket: DecodableDockPacket {

    public enum DecodingError: Error {
        case missingNewtonInfo
        case missingLength
        case invalidString
    }

    public static let command: DockCommand = .newtonName

    let newtonInfo: NewtonInfo

    let name: String

    public init(data: Data) throws {
        var data = data

        let newtonInfoLength = MemoryLayout<NewtonInfo>.size

        guard data.count >= newtonInfoLength else {
            throw DecodingError.missingNewtonInfo
        }

        // length
        guard
            let rawLength = UInt32(bigEndianData: data),
            case let length = Int(rawLength)
        else {
            throw DecodingError.missingLength
        }
        data = data.dropFirst(MemoryLayout<UInt32>.size)

        // Newton info
        newtonInfo = NewtonInfo.decode(data: data)
        data = data.dropFirst(length)

        // Newton name
        guard let name = String(data: data, encoding: .utf16BigEndian) else {
            throw DecodingError.invalidString
        }
        self.name = name
    }
}


