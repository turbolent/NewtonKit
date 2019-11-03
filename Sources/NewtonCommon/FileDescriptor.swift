
import Foundation
import Dispatch


#if os(Linux) || os(FreeBSD)
import var Glibc.errno
#elseif os(macOS) || os(iOS)
import var Darwin.C.errno
#endif


public struct FileDescriptor {

    public enum Error: Swift.Error {
        case failedToOpen(errno: Int32)
        case failedToRead(errno: Int32)
        case failedToWrite(errno: Int32)
        case failedToClose(errno: Int32)
    }

    public private(set) var fd: Int32

    public init(fd: Int32) {
        self.fd = fd
    }

    public init(path: String, oflag: Int32) throws {
        let fd = open(path, oflag)
        guard fd >= 0 else {
            throw Error.failedToOpen(errno: errno)
        }
        self.init(fd: fd)
    }

    public func read(count: Int) throws -> Data? {
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
        defer {
            buffer.deallocate()
        }
        #if os(Linux) || os(FreeBSD)
        let status = Glibc.read(fd, buffer, count)
        #elseif os(macOS) || os(iOS)
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

    public func write(data: Data) throws {
        _ = try data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
            let count = data.count

            #if os(Linux) || os(FreeBSD)
            let status = Glibc.write(fd, p.baseAddress, count)
            #elseif os(macOS) || os(iOS)
            let status = Darwin.write(fd, p.baseAddress, count)
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
        #elseif os(macOS) || os(iOS)
        let status = Darwin.close(fd)
        #endif

        guard status == 0 else {
            throw Error.failedToClose(errno: errno)
        }
    }
}
