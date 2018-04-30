
import Foundation
import Darwin.C.errno


public final class NewtonSerialPort {

    public enum Error: Swift.Error {
        case failedToOpen
        case failedToGetSettings
        case failedToSetSpeed
        case failedToSetSettings
        case failedToClose
        case notOpen
        case failedToRead(errno: Int32)
        case failedToWrite(errno: Int32)
    }

    private var fd: Int32?
    private var source: DispatchSourceRead?

    public var onRead: ((Data) throws -> Void)?
    public var onCancel: (() -> Void)?

    public let path: String

    public var isOpen: Bool {
        return fd != nil
    }

    public init(path: String) throws {
        self.path = path
    }

    public func open() throws {
        let fd = try open(path: path)
        self.fd = fd
        try configure(fd: fd)
    }

    private func open(path: String) throws -> Int32 {
        let fd = Darwin.open(path, O_RDWR | O_NOCTTY | O_NONBLOCK)
        guard fd >= 0 else {
            throw Error.failedToOpen
        }
        return fd
    }

    private func configure(fd: Int32) throws {
        var settings = termios()
        guard tcgetattr(fd, &settings) == 0 else {
            throw Error.failedToGetSettings
        }
        cfmakeraw(&settings)
        guard cfsetspeed(&settings, speed_t(B38400)) == 0 else {
            throw Error.failedToSetSpeed
        }
        settings.c_iflag |= tcflag_t(IGNBRK)
        settings.c_lflag &= ~tcflag_t(ICANON | ECHO | ECHOE | ISIG)
        settings.c_oflag &= ~tcflag_t(OPOST)
        settings.c_cflag &= ~tcflag_t((CSIZE | CSTOPB | PARENB))
        settings.c_cflag |= tcflag_t(CREAD | CLOCAL | CS8)

        // would be needed when reading in blocking mode:
        // VMIN: settings.c_cc.16 = 1
        // VTIME: settings.c_cc.17 = 0

        guard tcsetattr(fd, TCSANOW, &settings) == 0 else {
            throw Error.failedToSetSettings
        }
    }

    private func createSource(fd: Int32) -> DispatchSourceRead {
        // see https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/GCDWorkQueues/GCDWorkQueues.html
        let source = DispatchSource.makeReadSource(fileDescriptor: fd,
                                                   queue: DispatchQueue.global())
        source.setEventHandler(handler: handleReadEvent)
        source.setCancelHandler(handler: handleReadCancellation)
        return source
    }

    private func handleReadEvent() {
        guard
            let source = source,
            let fd = fd
        else {
            return
        }

        let estimated = Int(clamping: source.data + 1)
        do {
            guard let data = try read(fd: fd, count: estimated), !data.isEmpty else {
                return
            }

            try onRead?(data)
        } catch {
//            try? close()
        }
    }

    private func read(fd: Int32, count: Int) throws -> Data?{
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer {
            buffer.deallocate(capacity: count)
        }
        let count = Darwin.read(fd, buffer, count)

        // error?
        guard count >= 0 else {
            throw Error.failedToRead(errno: errno)
        }

        // end of file?
        guard count > 0 else {
            return nil
        }

        return Data(bytes: buffer, count: count)
    }

    private func handleReadCancellation() {
        try? close()
        onCancel?()
    }

    public func startReading() throws {
        guard let fd = fd else {
            throw Error.notOpen
        }
        source?.cancel()
        source = createSource(fd: fd)
        source?.resume()
    }

    public func stopReading() {
        if let source = source, !source.isCancelled {
            source.cancel()
        }
        source = nil
    }

    public func write(data: Data) throws {
        guard let fd = fd else {
            throw Error.notOpen
        }
        _ = try data.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            let rawPointer = UnsafeRawPointer(p)
            let count = data.count
            guard Darwin.write(fd, rawPointer, count) == count else {
                throw Error.failedToWrite(errno: errno)
            }
            return
        }
    }

    public func close() throws {
        if source != nil {
            stopReading()
        }
        guard let fd = fd else {
            return
        }
        guard Darwin.close(fd) == 0 else {
            throw Error.failedToClose
        }
        self.fd = nil
    }
}
