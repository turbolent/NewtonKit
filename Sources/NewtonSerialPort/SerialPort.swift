
public struct SerialPort: Hashable {
    public let calloutDevice: String
    public let usbVendorName: String?
    public let usbProductName: String?
    public let usbSerialNumber: String?

    public static func ==(lhs: SerialPort, rhs: SerialPort) -> Bool {
        return lhs.calloutDevice == rhs.calloutDevice
    }

    #if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
        hasher.combine(calloutDevice)
    }
    #else
    public var hashValue: Int {
        return calloutDevice.hashValue
    }
    #endif

    public var name: String {
        if let usbVendorName = usbVendorName,
            let usbProductName = usbProductName
        {
            return "\(usbVendorName) – \(usbProductName)"
        } else {
            return calloutDevice
        }
    }
}

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

import IOKit

internal extension SerialPort {

    init?(service: io_object_t) {
        guard let calloutDevice = service[kIOCalloutDeviceKey] as String? else {
            return nil
        }

        self.init(
            calloutDevice: calloutDevice,
            usbVendorName: service.getParentProperty(key: "USB Vendor Name"),
            usbProductName: service.getParentProperty(key: "USB Product Name"),
            usbSerialNumber: service.getParentProperty(key: "USB Serial Number")
        )
    }
}

#endif
