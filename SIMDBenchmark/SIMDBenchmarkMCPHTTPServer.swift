import Darwin
import Foundation

final class SIMDBenchmarkMCPHTTPServer: @unchecked Sendable {
    static let defaultPort: UInt16 = 8765

    let port: UInt16

    private let service = SIMDBenchmarkMCPService()
    private let endpointPath = "/mcp"
    private let lock = NSLock()
    private let acceptQueue = DispatchQueue(label: "SIMDBenchmark.MCPHTTPServer.accept", qos: .utility)
    private let connectionQueue = DispatchQueue(
        label: "SIMDBenchmark.MCPHTTPServer.connection",
        qos: .utility,
        attributes: .concurrent
    )
    private var serverSocket: Int32 = -1
    private var hasStarted = false

    var endpointURL: String {
        "http://127.0.0.1:\(port)\(endpointPath)"
    }

    init(port: UInt16 = SIMDBenchmarkMCPHTTPServer.defaultPort) {
        self.port = port
    }

    deinit {
        stop()
    }

    func start() throws {
        guard !isStarted else {
            return
        }

        let socket = try makeSocket()
        let shouldStart = withLock {
            if hasStarted {
                return false
            }

            hasStarted = true
            serverSocket = socket
            return true
        }

        guard shouldStart else {
            Darwin.close(socket)
            return
        }

        acceptQueue.async { [self] in
            run(socket: socket)
        }
    }

    func stop() {
        let socket = withLock {
            hasStarted = false
            let socket = serverSocket
            serverSocket = -1
            return socket
        }

        guard socket >= 0 else {
            return
        }

        Darwin.shutdown(socket, SHUT_RDWR)
        Darwin.close(socket)
    }

    private func run(socket: Int32) {
        while currentSocket == socket {
            var address = sockaddr_storage()
            var addressLength = socklen_t(MemoryLayout<sockaddr_storage>.size)
            let clientSocket = withUnsafeMutablePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                    Darwin.accept(socket, sockaddrPointer, &addressLength)
                }
            }

            if clientSocket < 0 {
                if errno == EINTR {
                    continue
                }

                break
            }

            connectionQueue.async { [self] in
                handleClient(socket: clientSocket)
            }
        }

        stop()
    }

    private var isStarted: Bool {
        withLock {
            hasStarted
        }
    }

    private var currentSocket: Int32 {
        withLock {
            serverSocket
        }
    }

    private func makeSocket() throws -> Int32 {
        let socket = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard socket >= 0 else {
            throw MCPHTTPServerError.posix(operation: "socket")
        }

        do {
            var reuseAddress: Int32 = 1
            guard Darwin.setsockopt(
                socket,
                SOL_SOCKET,
                SO_REUSEADDR,
                &reuseAddress,
                socklen_t(MemoryLayout<Int32>.size)
            ) == 0 else {
                throw MCPHTTPServerError.posix(operation: "setsockopt(SO_REUSEADDR)")
            }

            var noSIGPIPE: Int32 = 1
            _ = Darwin.setsockopt(
                socket,
                SOL_SOCKET,
                SO_NOSIGPIPE,
                &noSIGPIPE,
                socklen_t(MemoryLayout<Int32>.size)
            )

            var address = sockaddr_in()
            address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
            address.sin_family = sa_family_t(AF_INET)
            address.sin_port = in_port_t(port).bigEndian
            address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))

            let bindResult = withUnsafePointer(to: &address) { pointer in
                pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) { sockaddrPointer in
                    Darwin.bind(socket, sockaddrPointer, socklen_t(MemoryLayout<sockaddr_in>.size))
                }
            }

            guard bindResult == 0 else {
                throw MCPHTTPServerError.posix(operation: "bind")
            }

            guard Darwin.listen(socket, SOMAXCONN) == 0 else {
                throw MCPHTTPServerError.posix(operation: "listen")
            }

            return socket
        } catch {
            Darwin.close(socket)
            throw error
        }
    }

    private func handleClient(socket: Int32) {
        defer {
            Darwin.close(socket)
        }

        var noSIGPIPE: Int32 = 1
        _ = Darwin.setsockopt(
            socket,
            SOL_SOCKET,
            SO_NOSIGPIPE,
            &noSIGPIPE,
            socklen_t(MemoryLayout<Int32>.size)
        )

        do {
            let request = try readHTTPRequest(from: socket)
            let response = makeResponse(for: request)
            try write(response, to: socket)
        } catch {
            let response = makeHTTPResponse(
                status: 400,
                reason: "Bad Request",
                body: makeJSONBody(["error": "Bad Request"]),
                contentType: "application/json"
            )
            try? write(response, to: socket)
        }
    }

    private func makeResponse(for request: HTTPRequest) -> Data {
        if hasDisallowedOrigin(request) {
            return makeHTTPResponse(
                status: 403,
                reason: "Forbidden",
                body: makeJSONBody(["error": "Origin is not allowed"]),
                contentType: "application/json"
            )
        }

        if request.method == "OPTIONS" {
            return makeHTTPResponse(status: 204, reason: "No Content", request: request)
        }

        if request.method == "GET", request.path == "/health" {
            return makeHTTPResponse(
                status: 200,
                reason: "OK",
                body: makeJSONBody([
                    "status": "ok",
                    "endpoint": endpointURL
                ]),
                contentType: "application/json",
                request: request
            )
        }

        guard request.path == endpointPath else {
            return makeHTTPResponse(
                status: 404,
                reason: "Not Found",
                body: makeJSONBody(["error": "Not Found"]),
                contentType: "application/json",
                request: request
            )
        }

        guard request.method == "POST" else {
            return makeHTTPResponse(
                status: 405,
                reason: "Method Not Allowed",
                body: makeJSONBody(["error": "The MCP endpoint accepts JSON-RPC POST requests."]),
                contentType: "application/json",
                extraHeaders: ["Allow": "POST, OPTIONS"],
                request: request
            )
        }

        guard let jsonRPCResponse = service.handleMessageData(request.body) else {
            return makeHTTPResponse(status: 202, reason: "Accepted", request: request)
        }

        return makeHTTPResponse(
            status: 200,
            reason: "OK",
            body: jsonRPCResponse,
            contentType: "application/json",
            request: request
        )
    }

    private func readHTTPRequest(from socket: Int32) throws -> HTTPRequest {
        let headerTerminator = Data("\r\n\r\n".utf8)
        let maximumHeaderBytes = 32 * 1024
        let maximumBodyBytes = 1024 * 1024
        var buffer = Data()

        while buffer.range(of: headerTerminator) == nil {
            let chunk = try receiveChunk(from: socket)
            guard !chunk.isEmpty else {
                throw MCPHTTPServerError.badRequest("Empty request")
            }

            buffer.append(chunk)

            guard buffer.count <= maximumHeaderBytes else {
                throw MCPHTTPServerError.badRequest("Header is too large")
            }
        }

        guard let headerRange = buffer.range(of: headerTerminator) else {
            throw MCPHTTPServerError.badRequest("Missing header terminator")
        }

        let headerData = buffer[..<headerRange.lowerBound]
        guard let headerText = String(data: headerData, encoding: .utf8) else {
            throw MCPHTTPServerError.badRequest("Header is not UTF-8")
        }

        let lines = headerText.components(separatedBy: "\r\n")
        guard
            let requestLine = lines.first,
            let request = parseRequestLine(requestLine)
        else {
            throw MCPHTTPServerError.badRequest("Invalid request line")
        }

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            let pieces = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard pieces.count == 2 else {
                continue
            }

            headers[String(pieces[0]).lowercased()] = pieces[1].trimmingCharacters(in: .whitespaces)
        }

        let contentLength: Int
        if let contentLengthText = headers["content-length"] {
            guard let parsedContentLength = Int(contentLengthText), parsedContentLength >= 0 else {
                throw MCPHTTPServerError.badRequest("Invalid Content-Length")
            }

            contentLength = parsedContentLength
        } else {
            contentLength = 0
        }

        guard contentLength <= maximumBodyBytes else {
            throw MCPHTTPServerError.badRequest("Body is too large")
        }

        var body = Data(buffer[headerRange.upperBound...])
        while body.count < contentLength {
            let chunk = try receiveChunk(from: socket)
            guard !chunk.isEmpty else {
                throw MCPHTTPServerError.badRequest("Body ended early")
            }

            body.append(chunk)
        }

        if body.count > contentLength {
            body = body.prefix(contentLength)
        }

        return HTTPRequest(
            method: request.method,
            path: request.path,
            headers: headers,
            body: body
        )
    }

    private func parseRequestLine(_ requestLine: String) -> (method: String, path: String)? {
        let parts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else {
            return nil
        }

        let rawPath = parts[1]
        let path = rawPath.split(separator: "?", maxSplits: 1).first.map(String.init) ?? rawPath

        return (parts[0].uppercased(), path)
    }

    private func receiveChunk(from socket: Int32) throws -> Data {
        var bytes = [UInt8](repeating: 0, count: 8192)

        while true {
            let byteCount = bytes.withUnsafeMutableBytes { rawBuffer in
                Darwin.recv(socket, rawBuffer.baseAddress, rawBuffer.count, 0)
            }

            if byteCount < 0, errno == EINTR {
                continue
            }

            guard byteCount >= 0 else {
                throw MCPHTTPServerError.posix(operation: "recv")
            }

            return Data(bytes.prefix(byteCount))
        }
    }

    private func write(_ data: Data, to socket: Int32) throws {
        try data.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else {
                return
            }

            var offset = 0
            while offset < data.count {
                let sentByteCount = Darwin.send(socket, baseAddress.advanced(by: offset), data.count - offset, 0)

                if sentByteCount < 0, errno == EINTR {
                    continue
                }

                guard sentByteCount > 0 else {
                    throw MCPHTTPServerError.posix(operation: "send")
                }

                offset += sentByteCount
            }
        }
    }

    private func makeHTTPResponse(
        status: Int,
        reason: String,
        body: Data = Data(),
        contentType: String? = nil,
        extraHeaders: [String: String] = [:],
        request: HTTPRequest? = nil
    ) -> Data {
        var headers: [String: String] = [
            "Content-Length": "\(body.count)",
            "Connection": "close",
            "Cache-Control": "no-store",
            "MCP-Protocol-Version": SIMDBenchmarkMCPService.protocolVersion
        ]

        if let contentType {
            headers["Content-Type"] = contentType
        }

        if let request, let origin = allowedOrigin(for: request) {
            headers["Access-Control-Allow-Origin"] = origin
            headers["Access-Control-Allow-Methods"] = "POST, GET, OPTIONS"
            headers["Access-Control-Allow-Headers"] = "Content-Type, Accept, MCP-Protocol-Version, Mcp-Session-Id"
            headers["Vary"] = "Origin"
        }

        for (key, value) in extraHeaders {
            headers[key] = value
        }

        var headerText = "HTTP/1.1 \(status) \(reason)\r\n"
        for key in headers.keys.sorted() {
            headerText += "\(key): \(headers[key] ?? "")\r\n"
        }
        headerText += "\r\n"

        var response = Data(headerText.utf8)
        response.append(body)

        return response
    }

    private func makeJSONBody(_ object: [String: Any]) -> Data {
        (try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])) ?? Data("{}".utf8)
    }

    private func hasDisallowedOrigin(_ request: HTTPRequest) -> Bool {
        guard let origin = request.headers["origin"], !origin.isEmpty else {
            return false
        }

        return allowedOrigin(for: request) == nil
    }

    private func allowedOrigin(for request: HTTPRequest) -> String? {
        guard let origin = request.headers["origin"], !origin.isEmpty else {
            return nil
        }

        guard
            let components = URLComponents(string: origin),
            let scheme = components.scheme?.lowercased(),
            let host = components.host?.lowercased(),
            scheme == "http" || scheme == "https"
        else {
            return nil
        }

        let loopbackHosts: Set<String> = ["localhost", "127.0.0.1", "::1"]
        return loopbackHosts.contains(host) ? origin : nil
    }

    private func withLock<T>(_ body: () -> T) -> T {
        lock.lock()
        defer {
            lock.unlock()
        }

        return body()
    }
}

private struct HTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data
}

private enum MCPHTTPServerError: Error, CustomStringConvertible, LocalizedError {
    case badRequest(String)
    case posix(operation: String, code: Int32, message: String)

    static func posix(operation: String) -> MCPHTTPServerError {
        MCPHTTPServerError.posix(
            operation: operation,
            code: errno,
            message: String(cString: strerror(errno))
        )
    }

    var description: String {
        switch self {
        case .badRequest(let message):
            "Bad request: \(message)"
        case .posix(let operation, let code, let message):
            "\(operation) failed with errno \(code): \(message)"
        }
    }

    var errorDescription: String? {
        description
    }
}
