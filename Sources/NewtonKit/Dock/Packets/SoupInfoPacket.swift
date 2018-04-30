
import Foundation
import NSOF


public struct SoupInfoPacket: DecodableDockPacket {

    public static let command: DockCommand = .soupInfo

    public enum DecodingError: Error {
        case missingOrInvalidSoupInfo
    }

    public let soupInfo: NewtonFrame

    public init(data: Data) throws {
        guard case let (soupInfo as NewtonFrame, _) =
            try NewtonObjectDecoder.decodeRoot(data: data)
        else {
            throw DecodingError.missingOrInvalidSoupInfo
        }
        self.soupInfo = soupInfo
    }
}
