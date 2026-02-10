import Foundation
import OSLog

public protocol NetworkLogging: Sendable {
    func logRequest(_ request: URLRequest)
    func logResponse(_ response: URLResponse?, data: Data?, error: Error?)
    func logError(_ error: NetworkError)
}

public final class NetworkLogger: NetworkLogging, @unchecked Sendable {
    private let logger: Logger
    private let isEnabled: Bool

    public init(
        subsystem: String = Bundle.main.bundleIdentifier ?? "NetworkKit",
        category: String = "Network",
        isEnabled: Bool = true
    ) {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.isEnabled = isEnabled
    }

    public func logRequest(_ request: URLRequest) {
        guard isEnabled else { return }

        logger.info("REQUEST \(request.httpMethod ?? "N/A") \(request.url?.absoluteString ?? "N/A")")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            logger.debug("Headers: \(headers.description)")
        }

        if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            logger.debug("Body: \(bodyString)")
        }
    }

    public func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {
        guard isEnabled else { return }

        if let error = error {
            logger.error("RESPONSE ERROR: \(error.localizedDescription)")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.warning("Invalid response type")
            return
        }

        let statusCode = httpResponse.statusCode
        let level: OSLogType = (200..<300).contains(statusCode) ? .info : .error

        logger.log(level: level, "RESPONSE \(statusCode) \(httpResponse.url?.absoluteString ?? "N/A")")

        if let data = data {
            logger.debug("Data Size: \(data.count) bytes")
            if let jsonString = String(data: data, encoding: .utf8) {
                logger.debug("Body: \(jsonString)")
            }
        }
    }

    public func logError(_ error: NetworkError) {
        guard isEnabled else { return }
        logger.error("Network Error: \(error.errorDescription ?? "Unknown")")
    }
}

// MARK: - Silent Logger

public final class SilentNetworkLogger: NetworkLogging {
    public init() {}
    public func logRequest(_ request: URLRequest) {}
    public func logResponse(_ response: URLResponse?, data: Data?, error: Error?) {}
    public func logError(_ error: NetworkError) {}
}
