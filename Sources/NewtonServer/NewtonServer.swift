import Foundation
import CoreFoundation
import Dispatch
import NewtonCommon
import CDNS_SD

#if os(Linux) || os(FreeBSD)
import Glibc
#endif

public final class NewtonServer {

    public static let newtonDockPort: UInt16 = 3679

    public enum SocketError: Error {
        case failedToCreate
        case failedToBind
        case failedToListen
        case failedToDisablePipeSignal
        case failedToReuseAddress
        case failedToAnnounce
        case notConnected
    }

    private var dnsServiceRef: DNSServiceRef? = nil
    private var socket: CFSocket? = nil
    private var socketFileDescriptor: FileDescriptor? = nil
    private var connectionSource: DispatchSourceRead? = nil
    private var clientFileDescriptor: FileDescriptor? = nil
    private var readSource: DispatchSourceRead? = nil

    public var onConnect: ((_ host: String) -> Void)?
    public var onDisconnect: (() -> Void)?
    public var onRead: ((Data) throws -> Void)?
    public var onReadError: ((Swift.Error) -> Void)?
    public var onClose: (() -> Void)?

    public let port: UInt16

    public init(port: UInt16 = NewtonServer.newtonDockPort) {
        self.port = port

        #if os(Linux) || os(FreeBSD)
        setenv("AVAHI_COMPAT_NOWARN", "1", 1)
        #endif
    }

    public var isListening: Bool {
        return socket != nil
    }

    public var isAnnouncingService: Bool {
        return dnsServiceRef != nil
    }

    public func startListening() throws {
        let socket = try createSocket()
        try bind(socket: socket)

        let fd = CFSocketGetNative(socket)
        let fileDescriptor = FileDescriptor(fd: fd)

        let source = createConnectionSource(fileDescriptor: fileDescriptor)
        try listen(fileDescriptor: fileDescriptor)

        try startAnnouncingService()

        self.socket = socket
        socketFileDescriptor = fileDescriptor
        connectionSource = source
    }

    private func listen(fileDescriptor: FileDescriptor) throws {
        #if os(Linux) || os(FreeBSD)
        let listenResult = Glibc.startListening(fileDescriptor.fd, 16)
        #elseif os(macOS) || os(iOS)
        let listenResult = Darwin.listen(fileDescriptor.fd, 16)
        #endif
        guard listenResult == 0 else {
            throw SocketError.failedToListen
        }
    }

    private func createSocket() throws -> CFSocket {

        #if os(Linux) || os(FreeBSD)
        let optSocket = CFSocketCreate(
            kCFAllocatorDefault,
            PF_INET,
            Int32(SOCK_STREAM.rawValue),
            Int32(IPPROTO_TCP),
            0,
            nil,
            nil
        )
        #elseif os(macOS) || os(iOS)
        let optSocket = CFSocketCreate(
            kCFAllocatorDefault,
            PF_INET,
            SOCK_STREAM,
            IPPROTO_TCP,
            0,
            nil,
            nil
        )
        #endif

        guard let socket = optSocket else {
            throw SocketError.failedToCreate
        }

        return socket
    }

    private func bind(socket: CFSocket) throws {

        #if os(Linux) || os(FreeBSD)
        var address = sockaddr_in(
            sin_family: sa_family_t(AF_INET),
            sin_port: in_port_t(port.bigEndian),
            sin_addr: in_addr(s_addr: INADDR_ANY),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )
        #elseif os(macOS) || os(iOS)
        var address = sockaddr_in(
            sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
            sin_family: sa_family_t(AF_INET),
            sin_port: in_port_t(port.bigEndian),
            sin_addr: in_addr(s_addr: INADDR_ANY),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )
        #endif

        let addressData = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<sockaddr_in>.size) {
                CFDataCreate(kCFAllocatorDefault, $0, MemoryLayout<sockaddr_in>.size)
            }
        }

        try reuseAddress(fd: CFSocketGetNative(socket))

        #if os(Linux) || os(FreeBSD)
        let socketSuccess = kCFSocketSuccess
        #elseif os(macOS) || os(iOS)
        let socketSuccess = CFSocketError.success
        #endif

        guard CFSocketSetAddress(socket, addressData) == socketSuccess else {
            CFSocketInvalidate(socket)
            throw SocketError.failedToBind
        }
    }

    public func startAnnouncingService() throws {
        stopAnnouncingService()

        var dnsServiceRef = DNSServiceRef(bitPattern: 0)
        let type = "_newton-dock._tcp."
        let registrationResult =
            DNSServiceRegister(&dnsServiceRef, 0, 0, nil, type, nil, nil, port, 0, nil, nil, nil)
        guard
            registrationResult == kDNSServiceErr_NoError,
            dnsServiceRef != nil
        else {
            throw SocketError.failedToAnnounce
        }

        self.dnsServiceRef = dnsServiceRef
    }

    public func stopAnnouncingService() {
        if let dnsServiceRef = dnsServiceRef {
            DNSServiceRefDeallocate(dnsServiceRef)
        }
        self.dnsServiceRef = nil
    }

    private func createConnectionSource(fileDescriptor: FileDescriptor) -> DispatchSourceRead {
        let source = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor.fd,
                                                   queue: .global())
        source.setEventHandler(handler: handleConnectionEvent)
        source.setCancelHandler(handler: handleConnectionCancellation)
        source.resume()
        return source
    }

    private func handleConnectionEvent() {
        guard let socketFileDescriptor = socketFileDescriptor else {
            return
        }

        var length: socklen_t = 0

        #if os(Linux) || os(FreeBSD)
        var clientAddress = sockaddr()
        #elseif os(macOS) || os(iOS)
        var clientAddress = sockaddr(
            sa_len: 0,
            sa_family: 0,
            sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
        )
        #endif

        // NOTE: always accept, even if there is already a connection active
        let clientFD = accept(socketFileDescriptor.fd, &clientAddress, &length)
        guard clientFD != -1 else {
            return
        }

        let clientFileDescriptor = FileDescriptor(fd: clientFD)

        // NOTE: only allow one connection at a time: close after accept
        guard self.clientFileDescriptor == nil else {
            try? clientFileDescriptor.close()
            return
        }

        let host = withUnsafePointer(to: &clientAddress) { (pointer: UnsafePointer<sockaddr>) in
            pointer.withMemoryRebound(to: sockaddr_in.self, capacity: MemoryLayout<sockaddr_in>.size) {
                getHost(socketAddress: $0.pointee)
            }
        }

        do {
            try disablePipeSignal(fd: clientFD)
        } catch {
            return
        }

        self.clientFileDescriptor = clientFileDescriptor
        readSource = createReadSource(fileDescriptor: clientFileDescriptor)

        onConnect?(host)
    }

    private func getHost(socketAddress: sockaddr_in) -> String {
        var socketAddress = socketAddress
        var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        inet_ntop(AF_INET, &socketAddress.sin_addr, &buffer, socklen_t(INET_ADDRSTRLEN))
        return String(cString: buffer)
    }

    private func disablePipeSignal(fd: Int32) throws {
        #if os(Linux)
        // There is no SO_NOSIGPIPE in Linux and FreeBSD. We could instead use the MSG_NOSIGNAL flag
        // when calling send(), or use signal(SIGPIPE, SIG_IGN) to ignore SIGPIPE.
        #elseif os(macOS) || os(iOS)
        var no_sig_pipe: Int32 = 1
        let result = setsockopt(
            fd,
            SOL_SOCKET,
            SO_NOSIGPIPE,
            &no_sig_pipe,
            socklen_t(MemoryLayout<Int32>.size)
        )
        guard result == 0 else {
            throw SocketError.failedToDisablePipeSignal
        }
        #endif
    }

    private func reuseAddress(fd: Int32) throws {
        var yes: Int32 = 1
        let result = setsockopt(
            fd,
            Int32(SOL_SOCKET),
            Int32(SO_REUSEADDR),
            &yes,
            socklen_t(MemoryLayout<Int32>.size)
        )
        guard result == 0 else {
            throw SocketError.failedToReuseAddress
        }
    }

    private func createReadSource(fileDescriptor: FileDescriptor) -> DispatchSourceRead {
        let source = DispatchSource.makeReadSource(fileDescriptor: fileDescriptor.fd,
                                                   queue: .global())
        source.setEventHandler(handler: handleReadEvent)
        source.setCancelHandler(handler: handleReadCancellation)
        source.resume()
        return source
    }

    private func handleReadEvent() {
        guard
            let source = readSource,
            let fileDescriptor = clientFileDescriptor
        else {
            return
        }

        guard source.data > 0 else {
            handleReadCancellation()
            return
        }

        let estimated = Int(clamping: source.data + 1)
        do {
            guard let data = try fileDescriptor.read(count: estimated) else {
                handleReadCancellation()
                return
            }

            guard !data.isEmpty else {
                handleReadCancellation()
                return
            }

            try onRead?(data)
        } catch let error {
            stopListening()
            onReadError?(error)
        }
    }

    private func handleConnectionCancellation() {
        guard connectionSource != nil else {
            return
        }
        stopListening()
    }

    public func stopListening() {
        stopReading()

        if let source = connectionSource, !source.isCancelled {
            // NOTE: indicate to handleConnectionCancellation to not call
            // this method (stopListening) again
            connectionSource = nil
            source.cancel()
        }
        connectionSource = nil

        try? socketFileDescriptor?.close()
        socketFileDescriptor = nil

        defer {
            onClose?()
        }

        guard let socket = socket else {
            return
        }
        CFSocketInvalidate(socket)
        self.socket = nil
    }

    private func handleReadCancellation() {
        guard readSource != nil else {
            return
        }
        stopReading()
    }

    public func stopReading() {
        if let source = readSource, !source.isCancelled {
            // NOTE: indicate to handleReadCancellation to not call
            // this method (stopReading) again
            readSource = nil
            source.cancel()
        }
        readSource = nil
        try? clientFileDescriptor?.close()
        clientFileDescriptor = nil

        stopAnnouncingService()

        onDisconnect?()
    }

    public func write(data: Data) throws {
        guard let fileDescriptor = clientFileDescriptor else {
            throw SocketError.notConnected
        }
        try fileDescriptor.write(data: data)
    }
}
