
import Foundation


/// # Newton Formats
///
/// ## Package Container Format
///
/// ### Fixed header
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
        case invalidCopyrightOffset
        case invalidCopyrightLength
        case invalidCopyright
        case invalidNameOffset
        case invalidNameLength
        case invalidName
        case invalidSize
        case invalidDate
        case invalidPartCount
    }


    private static let signature = Data(bytes: "package".utf8)

    private static let partEntrySize = 32


    /// An arbitrary number used to identify the version of the package.
    /// The Newton OS interprets higher numbers as newer versions.

    let version: UInt32

    let copyright: String

    let name: String

    let size: UInt32

    let creationDate: Date

    public init(data: Data) throws {

        // Validate the signature
        //
        // > An eight-byte ASCII string specifying the format of the package.
        // > The signature "package0" signifies a package without a relocation
        // > information area; "package1" signifies a package that may contain
        // > one, depending on kRelocationFlag.

        let signatureLength = NewtonPackageInfo.signature.count

        guard data.count >= signatureLength else {
            throw DecodingError.invalidSignature
        }

        let signatureStartIndex = data.startIndex
        let signatureEndIndex = signatureStartIndex.advanced(by: signatureLength)
        let signatureData = data.subdata(in: signatureStartIndex..<signatureEndIndex)
        guard signatureData == NewtonPackageInfo.signature else {
            throw DecodingError.invalidSignature
        }

        // Skip last signature byte, `reserved1`, and `flags`.
        // Parse the version

        let versionStartIndex = signatureEndIndex.advanced(by: 1 + 2 * MemoryLayout<UInt32>.size)
        let versionEndIndex = versionStartIndex.advanced(by: MemoryLayout<UInt32>.size)
        let versionData = data.subdata(in: versionStartIndex..<versionEndIndex)
        guard let version = UInt32(bigEndianData: versionData) else {
            throw DecodingError.invalidVersion
        }

        self.version = version

        // Parse copyright InfoRef

        // > InfoRef: An unsigned 16-bit offset followed by an unsigned 16-bit length.
        // > InfoRefs are used to refer to variable-length data items in the variable-length data area
        // > of the package directory. The offset is from the beginning of the data area; the length
        // > is the number of bytes in the data item.

        let copyrightOffsetStartIndex = versionEndIndex
        let copyrightOffsetEndIndex = copyrightOffsetStartIndex.advanced(by: MemoryLayout<UInt16>.size)
        let copyrightOffsetData = data.subdata(in: copyrightOffsetStartIndex..<copyrightOffsetEndIndex)
        guard let copyrightOffset = UInt16(bigEndianData: copyrightOffsetData) else {
            throw DecodingError.invalidCopyrightOffset
        }

        let copyrightLengthStartIndex = copyrightOffsetEndIndex
        let copyrightLengthEndIndex = copyrightLengthStartIndex.advanced(by: MemoryLayout<UInt16>.size)
        let copyrightLengthData = data.subdata(in: copyrightLengthStartIndex..<copyrightLengthEndIndex)
        guard let copyrightLength = UInt16(bigEndianData: copyrightLengthData) else {
            throw DecodingError.invalidCopyrightLength
        }

        // Parse name InfoRef

        let nameOffsetStartIndex = copyrightLengthEndIndex
        let nameOffsetEndIndex = nameOffsetStartIndex.advanced(by: MemoryLayout<UInt16>.size)
        let nameOffsetData = data.subdata(in: nameOffsetStartIndex..<nameOffsetEndIndex)
        guard let nameOffset = UInt16(bigEndianData: nameOffsetData) else {
            throw DecodingError.invalidNameOffset
        }

        let nameLengthStartIndex = nameOffsetEndIndex
        let nameLengthEndIndex = nameLengthStartIndex.advanced(by: MemoryLayout<UInt16>.size)
        let nameLengthData = data.subdata(in: nameLengthStartIndex..<nameLengthEndIndex)
        guard let nameLength = UInt16(bigEndianData: nameLengthData) else {
            throw DecodingError.invalidNameLength
        }

        // Parse size

        let sizeStartIndex = nameLengthEndIndex
        let sizeEndIndex = sizeStartIndex.advanced(by: MemoryLayout<UInt32>.size)
        let sizeData = data.subdata(in: sizeStartIndex..<sizeEndIndex)
        guard let size = UInt32(bigEndianData: sizeData) else {
            throw DecodingError.invalidSize
        }

        self.size = size

        // Parse creation date
        //
        // > Date: Unsigned 32-bit integer representing a date and time
        // > as the number of seconds since midnight, January 4, 1904.

        let creationDateStartIndex = sizeEndIndex
        let creationDateEndIndex = creationDateStartIndex.advanced(by: MemoryLayout<UInt32>.size)
        let creationDateData = data.subdata(in: creationDateStartIndex..<creationDateEndIndex)
        guard let creationDate = UInt32(bigEndianData: creationDateData) else {
            throw DecodingError.invalidDate
        }

        // NOTE: documentation specifies January 4, but every application seems to use January 1
        self.creationDate = Date(secondsSince1904: Int(creationDate))

        // Skip `reserved2`, `reserved3`, and `directorySize`
        // Parse part count

        let partCountStartIndex = creationDateEndIndex.advanced(by: 3 * MemoryLayout<UInt32>.size)
        let partCountEndIndex = partCountStartIndex.advanced(by: MemoryLayout<UInt32>.size)
        let partCountData = data.subdata(in: partCountStartIndex..<partCountEndIndex)
        guard let partCount = UInt32(bigEndianData: partCountData) else {
            throw DecodingError.invalidPartCount
        }

        let variableLengthDataOffset =
            partCountEndIndex + Int(partCount) * NewtonPackageInfo.partEntrySize

        // Parse copyright (remove null-termination)

        let copyrightStartIndex =
            data.startIndex.advanced(by: variableLengthDataOffset + Int(copyrightOffset))
        let copyrightEndIndex = copyrightStartIndex.advanced(by: Int(copyrightLength) - 2)
        let copyrightData = data.subdata(in: copyrightStartIndex..<copyrightEndIndex)
        guard let copyright = String(data: copyrightData, encoding: .utf16BigEndian) else {
            throw DecodingError.invalidCopyright
        }

        self.copyright = copyright

        // Parse name (remove null-termination)

        let nameStartIndex =
            data.startIndex.advanced(by: variableLengthDataOffset + Int(nameOffset))
        let nameEndIndex = nameStartIndex.advanced(by: Int(nameLength) - 2)
        let nameData = data.subdata(in: nameStartIndex..<nameEndIndex)
        guard let name = String(data: nameData, encoding: .utf16BigEndian) else {
            throw DecodingError.invalidName
        }

        self.name = name
    }

}
