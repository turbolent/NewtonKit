
import Foundation


public struct OperationDonePacket: CodableDockPacket {

    public static let command: DockCommand = .operationDone

    public init() {}

    public init(data: Data) throws {}

    public func encode() -> Data? {
        return nil
    }
}
