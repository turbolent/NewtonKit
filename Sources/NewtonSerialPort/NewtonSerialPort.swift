
import Foundation
import Dispatch


#if os(Linux) || os(FreeBSD)
    import var Glibc.errno
#else
    import var Darwin.C.errno
#endif


internal struct FileDescriptor {

    internal enum Error: Swift.Error {
        case failedToOpen(errno: Int32)
        case failedToRead(errno: Int32)
        case failedToWrite(errno: Int32)
        case failedToClose(errno: Int32)
    }

    internal private(set) var fd: Int32

    init(path: String, oflag: Int32) throws {
        let fd = open(path, oflag)
        guard fd >= 0 else {
            throw Error.failedToOpen(errno: errno)
        }
        self.fd = fd
    }

    internal func read(count: Int) throws -> Data? {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer {
            buffer.deallocate(capacity: count)
        }
        #if os(Linux) || os(FreeBSD)
            let status = Glibc.read(fd, buffer, count)
        #else
            let status = Darwin.read(fd, buffer, count)
        #endif

        // error?
        guard status >= 0 else {
            throw Error.failedToRead(errno: errno)
        }

        // end of file?
        guard status > 0 else {
            return nil
        }

        return Data(bytes: buffer, count: status)
    }

    internal func write(data: Data) throws {
        _ = try data.withUnsafeBytes { (p: UnsafePointer<UInt8>) in
            let rawPointer = UnsafeRawPointer(p)
            let count = data.count

            #if os(Linux) || os(FreeBSD)
                let status = Glibc.write(fd, rawPointer, count)
            #else
                let status = Darwin.write(fd, rawPointer, count)
            #endif

            guard status == count else {
                throw Error.failedToWrite(errno: errno)
            }
            return
        }
    }

    public func close() throws {
        #if os(Linux) || os(FreeBSD)
            let status = Glibc.close(fd)
        #else
            let status = Darwin.close(fd)
        #endif

        guard status == 0 else {
            throw Error.failedToClose(errno: errno)
        }
    }
}


public final class NewtonSerialPort {

    public enum Error: Swift.Error {
        case failedToGetSettings
        case failedToSetSpeed
        case failedToSetSettings
        case notOpen
    }

    private var fileDescriptor: FileDescriptor?
    private var source: DispatchSourceRead?

    public var onRead: ((Data) throws -> Void)?
    public var onCancel: (() -> Void)?

    public let path: String

    public var isOpen: Bool {
        return fileDescriptor != nil
    }

    public init(path: String) throws {
        self.path = path
    }

    public func open() throws {
        let fileDescriptor = try open(path: path)
        self.fileDescriptor = fileDescriptor
        try configure(fileDescriptor: fileDescriptor)
    }

    private func open(path: String) throws -> FileDescriptor {
        return try FileDescriptor(path: path, oflag: O_RDWR | O_NOCTTY | O_NONBLOCK)
    }

    private func configure(fileDescriptor: FileDescriptor) throws {
        var settings = termios()
        guard tcgetattr(fileDescriptor.fd, &settings) == 0 else {
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

        guard tcsetattr(fileDescriptor.fd, TCSANOW, &settings) == 0 else {
            throw Error.failedToSetSettings
        }
    }

    private func createSource(fileDescriptor: FileDescriptor) -> DispatchSourceRead {
        // see https://developer.apple.com/library/content/documentation/General/Conceptual/ConcurrencyProgrammingGuide/GCDWorkQueues/GCDWorkQueues.html
        let source = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor.fd,
                                                   queue: DispatchQueue.global())
        source.setEventHandler(handler: handleReadEvent)
        source.setCancelHandler(handler: handleReadCancellation)
        return source
    }

    private func handleReadEvent() {
        guard
            let source = source,
            let fileDescriptor = fileDescriptor
        else {
            return
        }

        let estimated = Int(clamping: source.data + 1)
        do {
            guard
                let data = try fileDescriptor.read(count: estimated),
                !data.isEmpty
            else {
                return
            }

            try onRead?(data)
        } catch {
//            try? close()
        }
    }

    private func handleReadCancellation() {
        try? close()
        onCancel?()
    }

    public func startReading() throws {
        guard let fileDescriptor = fileDescriptor else {
            throw Error.notOpen
        }
        source?.cancel()
        source = createSource(fileDescriptor: fileDescriptor)
        source?.resume()
    }

    public func stopReading() {
        if let source = source, !source.isCancelled {
            source.cancel()
        }
        source = nil
    }

    public func write(data: Data) throws {
        guard let fileDescriptor = fileDescriptor else {
            throw Error.notOpen
        }
        try fileDescriptor.write(data: data)
    }

    public func close() throws {
        if source != nil {
            stopReading()
        }
        try fileDescriptor?.close()
        fileDescriptor = nil
    }
}
