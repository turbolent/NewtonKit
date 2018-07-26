
import Foundation


public final class NewtonFrame: NewtonObject {

    public struct Slot {
        let tag: NewtonSymbol
        let value: NewtonObject
    }

    public enum DecodingError: Error {
        case missingSlotCount
        case invalidSlotKey
        case invalidSlotValue
    }

    /// Slot tags in ascending order (symbol objects)
    public let tags: [NewtonSymbol]

    /// Slot values in ascending order (objects)
    public let valuesByTag: [String: NewtonObject]

    public static func decode(decoder: NewtonObjectDecoder) throws -> NewtonFrame {

        // Number of slots (xlong)
        guard let slotCount = decoder.decodeXLong()  else {
            throw DecodingError.missingSlotCount
        }

        // Slot tags in ascending order (symbol objects)
        let tags: [NewtonSymbol] =
            try (0..<Int(slotCount)).map { _ in
                guard case let tag as NewtonSymbol =
                    try decoder.decodeObject()
                else {
                    throw DecodingError.invalidSlotKey
                }
                return tag
            }

        // Slot values in ascending order (objects)
        let slots: [Slot] =
            try tags.map { tag in
                guard let value = try decoder.decodeObject() else {
                    throw DecodingError.invalidSlotValue
                }
                return Slot(tag: tag, value: value)
            }

        return NewtonFrame(slots: slots)
    }

    public init(slots: [Slot]) {
        tags = slots.map { $0.tag }
        valuesByTag = [String: NewtonObject](uniqueKeysWithValues: slots.map {
            ($0.tag.name, $0.value)
        })
    }

    public subscript(tagName: String) -> NewtonObject? {
        get {
            return valuesByTag[tagName]
        }
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.frame.rawValue])
        data.append(NewtonObjectEncoder.encode(xlong: Int32(tags.count)))
        for tag in tags {
            data.append(encoder.encode(newtonObject: tag))
        }
        for tag in tags {
            data.append(encoder.encode(newtonObject: valuesByTag[tag.name]!))
        }
        return data
    }

    public static func rectangle(top: Int32, left: Int32, bottom: Int32, right: Int32) -> NewtonFrame {
        return [
            "top": NewtonInteger(integer: top),
            "left": NewtonInteger(integer: left),
            "bottom": NewtonInteger(integer: bottom),
            "right": NewtonInteger(integer: right)
        ] as NewtonFrame
    }
}


extension NewtonFrame: ExpressibleByDictionaryLiteral {

    public convenience init(dictionaryLiteral elements: (String, NewtonObject)...) {
        let slots = elements.map { element -> NewtonFrame.Slot in
            let (key, value) = element
            return Slot(tag: NewtonSymbol(name: key),
                        value: value)
        }
        self.init(slots: slots)
    }
}


extension NewtonFrame: CustomStringConvertible {

    public var description: String {
        let contents = tags
            .map { tag in
                let tagDescription = String(describing: tag)
                let value = valuesByTag[tag.name]!
                let valueDescription = String(describing: value)
                return [tagDescription, valueDescription]
                    .joined(separator: ": ")
            }
            .joined(separator: ", ")
        return "{ \(contents) }"
    }
}
