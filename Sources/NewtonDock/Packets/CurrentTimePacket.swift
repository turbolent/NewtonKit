
import Foundation
import CoreFoundation

// TODO:
/// From NCX:
///
/// "A NewtonScript date is classically the number of minutes
/// since 1904.
///
/// However…
///
/// Newton measures time in seconds since 1993, but 2^29 seconds
/// (signed NewtonScript integer) overflow in 2010.
///
/// Avi Drissman’s fix (Fix2010) for this is rebase seconds on
/// a hexade (16 years): 1993, 2009, 2025…"
///
/// The Newton returns the unpatched value of Time(), so it
/// needs to be offset here

public struct CurrentTimePacket: DecodableDockPacket {

    public static let command: DockCommand = .currentTime

    public enum DecodingError: Error {
        case invalidDate
    }

    public let date: Date

    public init(data: Data) throws {
        guard
            let rawMinutesSince1904 = UInt32(bigEndianData: data),
            case let minutesSince1904 = Int(rawMinutesSince1904)
        else {
            throw DecodingError.invalidDate
        }
        date = Date(minutesSince1904: minutesSince1904)
    }
}
