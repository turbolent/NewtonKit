
import Foundation


public struct RequestToInstallPacket: EncodableDockPacket {

    public static let command: DockCommand = .requestToInstall

    public init() {}

    public func encode() -> Data? {
        return nil
    }
}

