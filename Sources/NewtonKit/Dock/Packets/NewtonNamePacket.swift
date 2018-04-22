
import Foundation


public struct NewtonNamePacket: DecodableDockPacket {

    public static let command: DockCommand = .newtonName

    public init(data: Data) throws {}
}
