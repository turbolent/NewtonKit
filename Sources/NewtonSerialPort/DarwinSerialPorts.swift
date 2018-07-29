
#if os(macOS)

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

    public enum Error: Swift.Error {
        case matchingFailed
    }

    private var iterator: io_iterator_t
    private let release: Bool

    public convenience init() throws {
        var iterator: io_iterator_t = 0

        let result = IOServiceGetMatchingServices(kIOMasterPortDefault, serialPortMatching, &iterator)
        guard result == KERN_SUCCESS else {
            throw Error.matchingFailed
        }
        self.init(iterator: iterator, release: true)
    }

    public init(iterator: io_iterator_t, release: Bool) {
        self.iterator = iterator
        self.release = release
    }

    public func next() -> SerialPort? {
        guard case let service = IOIteratorNext(iterator), service != 0 else {
            return nil
        }

        defer {
            IOObjectRelease(service)
        }

        return SerialPort(service: service)
    }

    deinit {
        if release {
            IOObjectRelease(iterator)
        }
    }
}

#endif
