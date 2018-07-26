
#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)

import Foundation
import IOKit
import IOKit.serial

public class DarwinSerialPortMonitor: SerialPortMonitor {

    public enum Error: Swift.Error {
        case portCreationFailed
        case addMatchingNotificationFailed
        case addTerminatedNotificationFailed
    }

    private let notificationQueue =
        DispatchQueue(label: "com.turbolent.NewtonKit.DarwinSerialPortMonitor")
    private let notificationPort: IONotificationPortRef
    private var matchedIterator: io_iterator_t = 0
    private var terminatedIterator: io_iterator_t = 0

    public let callbackQueue: DispatchQueue
    public var callback: Callback

    private static let matchCallback: IOServiceMatchingCallback = { userData, iterator in
        let monitor =
            Unmanaged<DarwinSerialPortMonitor>.fromOpaque(userData!).takeUnretainedValue()
        monitor.dispatchEvent(event: .matched, iterator: iterator)
    }

    private static let termCallback: IOServiceMatchingCallback = { userData, iterator in
        let monitor =
            Unmanaged<DarwinSerialPortMonitor>.fromOpaque(userData!).takeUnretainedValue()
        monitor.dispatchEvent(event: .terminated, iterator: iterator)
    }

    public required init(callbackQueue: DispatchQueue, callback: @escaping Callback) throws {
        guard let notificationPort = IONotificationPortCreate(kIOMasterPortDefault) else {
            throw Error.portCreationFailed
        }

        self.notificationPort = notificationPort
        IONotificationPortSetDispatchQueue(notificationPort, notificationQueue)

        self.callbackQueue = callbackQueue
        self.callback = callback
    }

    public func start() throws {
        guard matchedIterator == 0 else {
            return
        }

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        // add matching notification

        let addMatchResult =
            IOServiceAddMatchingNotification(notificationPort,
                                             kIOPublishNotification,
                                             serialPortMatching,
                                             DarwinSerialPortMonitor.matchCallback,
                                             selfPointer,
                                             &matchedIterator)

        guard addMatchResult == KERN_SUCCESS else {
            if matchedIterator != 0 {
                IOObjectRelease(matchedIterator)
            }
            throw Error.addMatchingNotificationFailed
        }

        // add terminated notification

        let addTermResult =
            IOServiceAddMatchingNotification(notificationPort,
                                             kIOTerminatedNotification,
                                             serialPortMatching,
                                             DarwinSerialPortMonitor.termCallback,
                                             selfPointer,
                                             &terminatedIterator)

        guard addTermResult == KERN_SUCCESS else {
            if terminatedIterator != 0 {
                IOObjectRelease(terminatedIterator)
            }
            throw Error.addTerminatedNotificationFailed
        }

        // Always iterate both matched and terminated iterators, so notifications are properly emitted.
        // Handle terminated iterator first, so that matched iterator ends up in correct state.

        dispatchEvent(event: .terminated, iterator: terminatedIterator)
        dispatchEvent(event: .matched, iterator: matchedIterator)
    }

    public func stop() throws {
        guard matchedIterator != 0 else {
            return
        }

        IOObjectRelease(matchedIterator)
        IOObjectRelease(terminatedIterator)

        matchedIterator = 0
        terminatedIterator = 0
    }

    private func dispatchEvent(event: SerialPortMonitorEvent, iterator: io_iterator_t) {
        for serialPort in DarwinSerialPorts(iterator: iterator, release: false) {
            callbackQueue.async { [callback] in
                callback(event, serialPort)
            }
        }
    }

    deinit {
        try? stop()
    }
}

#endif
