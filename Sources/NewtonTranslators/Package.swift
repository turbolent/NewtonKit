
import Foundation


/// # Newton Formats
///
/// ## Package Container Format
///
/// ### Package Directory
///
/// #### Fixed header
///
/// The package directory begins with a fixed set of fields represented by the
/// PackageDirectory structure.
///
/// ```c
/// struct PackageDirectory {
///     Byte signature[8];
///     ULong reserved1;
///     ULong flags;
///     ULong version;
///     InfoRef copyright;
///     InfoRef name;
///     ULong size;
///     Date creationDate;
///     ULong reserved2;
///     ULong reserved3;
///     ULong directorySize;
///     ULong numParts;
///     /* PartEntry parts[numParts]; */
///     /* Byte variableLengthData[]; */
/// }
/// ```
///
/// Fields reserved1, reserved2, and reserved3 are reserved and must be set to zero.

public struct NewtonPackageInfo {

    public enum DecodingError: Error {
        case invalidSignature
        case invalidVersion
        case invalidCopyrightInfoRef
        case invalidCopyright
        case invalidNameInfoRef
        case invalidName
        case invalidSize
        case invalidDate
        case invalidPartCount
    }


    /// > InfoRef: An unsigned 16-bit offset followed by an unsigned 16-bit length.
    /// > InfoRefs are used to refer to variable-length data items in the variable-length data area
    /// > of the package directory. The offset is from the beginning of the data area; the length
    /// > is the number of bytes in the data item.

    private static func parseInfoRef(data: Data, startIndex: Data.Index)
        -> (offset: Data.Index, length: Int, endIndex: Data.Index)?
    {

        guard
            case let (rawOffset, offsetEndIndex)?: (UInt16, Data.Index)? =
                data.sliceBigEndian(startIndex: startIndex),
            case let offset = Int(rawOffset)
        else {
            return nil
        }

        guard
            case let (rawLength, endIndex)?: (UInt16, Data.Index)? =
                data.sliceBigEndian(startIndex: offsetEndIndex),
            case let length = Int(rawLength)
        else {
            return nil
        }

        return (offset: offset, length: length, endIndex: endIndex)
    }

    private static let signature = "package".data(using: .utf8)!

    private static let partEntrySize = 32


    /// An arbitrary number used to identify the version of the package.
    /// The Newton OS interprets higher numbers as newer versions.

    public let version: UInt32

    public let copyright: String

    public let name: String

    public let size: UInt32

    public let creationDate: Date

    public init(data: Data) throws {

        // Validate the signature
        //
        // > An eight-byte ASCII string specifying the format of the package.
        // > The signature "package0" signifies a package without a relocation
        // > information area; "package1" signifies a package that may contain
        // > one, depending on kRelocationFlag.

        guard
            case let (signatureData, signatureEndIndex)? =
                data.slice(NewtonPackageInfo.signature.count),
            signatureData == NewtonPackageInfo.signature
        else {
            throw DecodingError.invalidSignature
        }

        // Skip last signature byte, `reserved1`, and `flags`.
        // Parse the version

        guard
            case let versionStartIndex =
                signatureEndIndex.advanced(by: 1 + 2 * MemoryLayout<UInt32>.size),
            case let (version, versionEndIndex)?: (UInt32, Data.Index)? =
                data.sliceBigEndian(startIndex: versionStartIndex)
        else {
            throw DecodingError.invalidVersion
        }

        self.version = version

        // Parse copyright InfoRef

        guard case let (copyrightOffset, copyrightLength, copyrightInfoRefEndIndex)? =
            NewtonPackageInfo.parseInfoRef(data: data, startIndex: versionEndIndex)
        else {
            throw DecodingError.invalidCopyrightInfoRef
        }

        // Parse name InfoRef

        guard case let (nameOffset, nameLength, nameInfoRefEndIndex)? =
            NewtonPackageInfo.parseInfoRef(data: data, startIndex: copyrightInfoRefEndIndex)
        else {
            throw DecodingError.invalidNameInfoRef
        }

        // Parse size

        guard case let (size, sizeEndIndex)?: (UInt32, Data.Index)? =
            data.sliceBigEndian(startIndex: nameInfoRefEndIndex)
        else {
            throw DecodingError.invalidSize
        }

        self.size = size

        // Parse creation date
        //
        // > Date: Unsigned 32-bit integer representing a date and time
        // > as the number of seconds since midnight, January 4, 1904.

        guard
            case let (rawCreationDate, creationDateEndIndex)?: (UInt32, Data.Index)? =
                data.sliceBigEndian(startIndex: sizeEndIndex),
            case let creationDate = Int(rawCreationDate)
        else {
            throw DecodingError.invalidDate
        }

        // NOTE: documentation specifies January 4, but every application seems to use January 1
        self.creationDate = Date(secondsSince1904: creationDate)

        // Skip `reserved2`, `reserved3`, and `directorySize`
        // Parse part count

        guard
            case let partCountStartIndex =
                creationDateEndIndex.advanced(by: 3 * MemoryLayout<UInt32>.size),
            case let (rawPartCount, partCountEndIndex)?: (UInt32, Data.Index)? =
                data.sliceBigEndian(startIndex: partCountStartIndex),
            case let partCount = Int(rawPartCount)
        else {
            throw DecodingError.invalidPartCount
        }

        let variableLengthDataOffset =
            partCountEndIndex + partCount * NewtonPackageInfo.partEntrySize

        // Parse copyright (remove null-termination)

        guard
            case let copyrightStartIndex =
                data.startIndex.advanced(by: variableLengthDataOffset + copyrightOffset),
            case let (copyrightData, _)? =
                data.slice(copyrightLength - 2, startIndex: copyrightStartIndex),
            let copyright = String(data: copyrightData, encoding: .utf16BigEndian)
        else {
            throw DecodingError.invalidCopyright
        }

        self.copyright = copyright

        // Parse name (remove null-termination)

        guard
            case let nameStartIndex =
                data.startIndex.advanced(by: variableLengthDataOffset + nameOffset),
            case let (nameData, _)? =
                data.slice(nameLength - 2, startIndex: nameStartIndex),
            let name = String(data: nameData, encoding: .utf16BigEndian)
        else {
            throw DecodingError.invalidName
        }

        self.name = name
    }
}
