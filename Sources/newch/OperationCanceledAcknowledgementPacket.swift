
import Foundation


public struct OperationCanceledAcknowledgementPacket: CodableDockPacket {

    public static let command: DockCommand = .operationCanceledAcknowledgement

    public init() {}

    public init(data: Data) throws {}

    public func encode() -> Data? {
        return nil
    }
}
