
import Foundation


public protocol DockPacket {
    static var command: DockCommand { get }
    init(data: Data) throws
    func encode() -> Data?
}
