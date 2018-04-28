
import Foundation


// Newton Streamed Object Format
//
// "[...] the format used when streaming a DAG (Directed Acyclic Graph)*
// of objects over a communications link."
//
// [...]
//
// The first byte of a coded object is a version byte that refers to the NSOF version. The
// version number of the format described here is 2. (Future versions may not be backward
// compatible.)
//
// The rest of the coded object is a recursive description of the DAG of objects, beginning
// with the root object.
//
// The beginning of each object’s description is a tag byte that specifies the encoding type
// used for the object.
//
// The tag byte is followed an ID, called a precedent ID. The IDs are assigned
// consecutively, starting with 0 for the root object, and are used by the kPrecedent tag to
// generate backward pointer references to objects that have already been introduced. Note
// that no object may be traversed more than once; any pointers to previously traversed
// objects must be represented with kPrecedent. Immediate objects cannot be precedents;
// all precedents are heap objects (binary objects, arrays, and frames)


public class NewtonObjectDecoder {

    public enum DecodingError: Error {
        case missingVersion
        case invalidVersion
        case missingType
        case invalidType
        case invalidImmediate
        case unsupportedType
        case missingPrecedentID
        case invalidPrecedentID
    }

    public static func decodeRoot(data: Data) throws -> NewtonObject? {
        let decoder = NewtonObjectDecoder(data: data)
        guard let version = decoder.decodeByte() else {
            throw DecodingError.missingVersion
        }

        guard version == 2 else {
            throw DecodingError.invalidVersion
        }

        return try decoder.decodeObject()
    }

    private var data: Data
    private var precedents: [NewtonObject] = []

    private init(data: Data) {
        self.data = data
    }

    private func recordPrecedent() -> Int {
        // temporary, will be patched in updatePrecedent
        precedents.append(NewtonNil.`nil`)
        return precedents.count - 1
    }

    private func getPrecedent(at precedentID: Int32) -> NewtonObject? {
        guard precedentID < precedents.count else {
            return nil
        }
        return precedents[Int(precedentID)]
    }

    private func updatePrecedent(at precedentID: Int, object: NewtonObject) {
        precedents[precedentID] = object
    }

    public func decodeXLong() -> Int32? {
        guard !data.isEmpty else {
            return nil
        }

        let first = Int32(data.removeFirst())

        if 0..<255 ~= first {
            return first
        }

        let xlong = Int32(bigEndianData: data)
        data.removeFirst(MemoryLayout<Int32>.size)
        return xlong
    }

    private func peekXLong() -> Int32? {
        guard let first = data.first else {
            return nil
        }
        let r = Int32(first)
        if 0..<255 ~= r {
            return r
        }
        return Int32(bigEndianData: data.dropFirst())
    }

    public func decodeByte() -> UInt8? {
        guard !data.isEmpty else {
            return nil
        }

        return data.removeFirst()
    }

    public func decodeUInt16() -> UInt16? {
        guard let value = UInt16(bigEndianData: data) else {
            return nil
        }

        data.removeFirst(MemoryLayout<UInt16>.size)
        return value
    }

    public func decodeData(n count: Int) -> Data? {
        guard self.data.count >= count else {
            return nil
        }

        let data = self.data.prefix(upTo: self.data.startIndex.advanced(by: count))
        self.data.removeFirst(count)
        return data
    }

    public func decodeObject() throws -> NewtonObject? {

        guard !data.isEmpty else {
            throw DecodingError.missingType
        }

        guard let type = NewtonObjectType(rawValue: data.removeFirst()) else {
            throw DecodingError.invalidType
        }

        switch type {
        case .precedent:
            guard let precedentID = decodeXLong() else {
                throw DecodingError.missingPrecedentID
            }
            guard let object = getPrecedent(at: precedentID) else {
                throw DecodingError.invalidPrecedentID
            }
            return object
        case .immediate:
            guard let immediate = peekXLong() else {
                throw DecodingError.invalidImmediate
            }
            if NewtonInteger.isInteger(immediate: immediate) {
                return try NewtonInteger.decode(decoder: self)
            } else if NewtonTrue.isTrue(immediate: immediate) {
                return try NewtonTrue.decode(decoder: self)
            } else if NewtonNil.isNil(immediate: immediate) {
                return NewtonNil.`nil`
            } else if NewtonCharacter.isCharacter(immediate: immediate) {
                return try NewtonCharacter.decodeImmediate(decoder: self)
            } else if NewtonMagicPointer.isMagicPointer(immediate: immediate) {
                return try NewtonMagicPointer.decode(decoder: self)
            } else {
                throw DecodingError.invalidImmediate
            }
        case .`nil`:
            return NewtonNil.`nil`
        default:
            guard let swiftType = type.swiftType else {
                throw DecodingError.unsupportedType
            }
            var precedentID: Int? = nil
            if NewtonObjectType.precedentTypes.contains(type) {
                precedentID = recordPrecedent()
            }
            let object = try swiftType.decode(decoder: self)
            if let precedentID = precedentID {
                updatePrecedent(at: precedentID, object: object)
            }
            return object
        }
    }
}
