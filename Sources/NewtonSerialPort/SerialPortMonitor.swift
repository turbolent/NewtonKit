
import Dispatch

public enum SerialPortMonitorEvent {
    case matched
    case terminated
}


/// Usage:
///
/// ```swift
/// let monitor = try DarwinSerialPortMonitor(callbackQueue: .global()) { event, port in
///     // ..
/// }
///
/// try monitor.start()
/// ```
///
public protocol SerialPortMonitor {

    typealias Callback = (SerialPortMonitorEvent, SerialPort) -> Void

    init(callbackQueue: DispatchQueue, callback: @escaping Callback) throws
    func start() throws
    func stop() throws
}
