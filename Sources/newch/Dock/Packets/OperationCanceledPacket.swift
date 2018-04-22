
import Foundation


public struct OperationCanceledPacket: CodableDockPacket {

    public static let command: DockCommand = .operationCanceled

    public init() {}

    public init(data: Data) throws {}

    public func encode() -> Data? {
        return nil
    }
}
