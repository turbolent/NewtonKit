
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

import Foundation
import IOKit
import IOKit.serial

internal extension io_object_t {

    internal subscript<T>(key: String) -> T? {
        let cfKey = key as CFString
        return IORegistryEntryCreateCFProperty(self, cfKey, kCFAllocatorDefault, 0)?
            .takeUnretainedValue() as? T
    }

    internal func getParentProperty<T>(key: String) -> T? {
        let cfKey = key as CFString
        let options = IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        return IORegistryEntrySearchCFProperty(self, kIOServicePlane, cfKey, kCFAllocatorDefault, options)
            as? T
    }
}

public class DarwinSerialPorts: SerialPorts {

    private var iterator: io_iterator_t = 0

    public init?() {
        let matching = IOServiceMatching(kIOSerialBSDServiceValue) as NSMutableDictionary
        matching[kIOSerialBSDTypeKey] = kIOSerialBSDRS232Type
        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &iterator)
        guard result == KERN_SUCCESS else {
            return nil
        }
    }

    public func next() -> SerialPort? {
        guard case let service = IOIteratorNext(iterator), service != 0 else {
            return nil
        }

        guard let calloutDevice = service[kIOCalloutDeviceKey] as String? else {
            return nil
        }

        return SerialPort(
            calloutDevice: calloutDevice,
            usbVendorName: service.getParentProperty(key: "USB Vendor Name"),
            usbProductName: service.getParentProperty(key: "USB Product Name"),
            usbSerialNumber: service.getParentProperty(key: "USB Serial Number")
        )
    }

    deinit {
        IOObjectRelease(iterator)
    }
}

#endif
