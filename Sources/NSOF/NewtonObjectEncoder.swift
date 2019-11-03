
import Foundation


/// # Newton Streamed Object Format
///
/// "[...] the format used when streaming a DAG (Directed Acyclic Graph)*
/// of objects over a communications link."
///
/// [...]
///
/// The first byte of a coded object is a version byte that refers to the NSOF version. The
/// version number of the format described here is 2. (Future versions may not be backward
/// compatible.)
///
/// The rest of the coded object is a recursive description of the DAG of objects, beginning
/// with the root object.
///
/// The beginning of each object’s description is a tag byte that specifies the encoding type
/// used for the object.
///
/// The tag byte is followed an ID, called a precedent ID. The IDs are assigned
/// consecutively, starting with 0 for the root object, and are used by the kPrecedent tag to
/// generate backward pointer references to objects that have already been introduced. Note
/// that no object may be traversed more than once; any pointers to previously traversed
/// objects must be represented with kPrecedent. Immediate objects cannot be precedents;
/// all precedents are heap objects (binary objects, arrays, and frames)

public class NewtonObjectEncoder {

    private static let precedentTypes: Set<ObjectIdentifier> =
        Set(NewtonObjectType.precedentTypes.compactMap {
            $0.swiftType.map {
                ObjectIdentifier($0)
            }
        })

    private static func isPrecedentType(type: NewtonObject.Type) -> Bool {
        return precedentTypes.contains(ObjectIdentifier(type))
    }

    // precedent IDs for all encoded objects whose type is a precedent type
    private var precedents: [ObjectIdentifier: Int32] = [:]

    private init() {}

    public static func encodeRoot(newtonObject: NewtonObject) -> Data {
        // Version
        var data = Data([2])
        let encoder = NewtonObjectEncoder()
        data.append(encoder.encode(newtonObject: newtonObject))
        return data
    }

    public func encode(newtonObject: NewtonObject) -> Data {
        let type = Swift.type(of: newtonObject)
        if NewtonObjectEncoder.isPrecedentType(type: type),
            let anyNewtonObject = newtonObject as? AnyObject
        {
            let identifier = ObjectIdentifier(anyNewtonObject)
            if let precedentID = precedents[identifier] {
                var data = Data([NewtonObjectType.precedent.rawValue])
                data.append(NewtonObjectEncoder.encode(xlong: precedentID))
                return data
            } else {
                precedents[identifier] = Int32(precedents.count)
            }
        }
        return newtonObject.encode(encoder: self)
    }

    public static func encode(xlong: Int32) -> Data {
        if 0..<255 ~= xlong {
            return Data([UInt8(xlong)])
        }
        var data = Data()
        data.append(0xFF)
        data.append(xlong.bigEndianData)
        return data
    }
}
