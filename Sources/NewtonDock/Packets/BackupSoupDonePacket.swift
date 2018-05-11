
import Foundation


public struct BackupSoupDonePacket: DecodableDockPacket {

    public static let command: DockCommand = .backupSoupDone

    public init(data: Data) throws {}
}
