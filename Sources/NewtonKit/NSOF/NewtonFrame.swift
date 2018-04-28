
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

    public let slots: [Slot]

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
        self.slots = slots
    }

    public func encode(encoder: NewtonObjectEncoder) -> Data {
        var data = Data(bytes: [NewtonObjectType.frame.rawValue])
        data.append(NewtonObjectEncoder.encode(xlong: Int32(slots.count)))
        for slot in slots {
            data.append(encoder.encode(newtonObject: slot.tag))
        }
        for slot in slots {
            data.append(encoder.encode(newtonObject: slot.value))
        }
        return data
    }
}
