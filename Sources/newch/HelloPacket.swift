
import Foundation


public struct HelloPacket: CodableDockPacket {

    public static let command: DockCommand = .hello

    public init() {}

    public init(data: Data) throws {}

    public func encode() -> Data? {
        return nil
    }
}
