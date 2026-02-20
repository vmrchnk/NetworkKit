import Foundation

// MARK: - Configuration

public struct NetworkClientConfiguration: Sendable {
    public let baseURL: String
    public let defaultHeaders: [String: String]

    public init(
        baseURL: String,
        defaultHeaders: [String: String] = [:]
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
    }
}

// MARK: - Session Cache

private actor SessionCache {
    private var sessions: [String: URLSession] = [:]

    func session(for provider: some SessionProvider) -> URLSession {
        if let existing = sessions[provider.identifier] {
            return existing
        }

        let session = URLSession(configuration: provider.makeConfiguration())
        sessions[provider.identifier] = session
        return session
    }
}

// MARK: - Network Client

public final class NetworkClient: Sendable {

    // MARK: - Shared Instance

    public static var shared: NetworkClient!

    private let configuration: NetworkClientConfiguration
    private let sessionCache: SessionCache
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let logger: NetworkLogging

    public init(
        configuration: NetworkClientConfiguration,
        decoder: JSONDecoder? = nil,
        encoder: JSONEncoder? = nil,
        logger: NetworkLogging? = nil
    ) {
        self.configuration = configuration
        self.sessionCache = SessionCache()

        self.decoder = decoder ?? {
            let d = JSONDecoder()
            d.dateDecodingStrategy = .iso8601
            d.keyDecodingStrategy = .convertFromSnakeCase
            return d
        }()

        self.encoder = encoder ?? {
            let e = JSONEncoder()
            e.dateEncodingStrategy = .iso8601
            e.keyEncodingStrategy = .convertToSnakeCase
            return e
        }()

        self.logger = logger ?? NetworkLogger()
    }

    // MARK: - Request Execution

    public func execute<R: Request>(_ request: R) async throws -> R.Response {
        let urlRequest = try buildURLRequest(for: request)
        let session = await sessionCache.session(for: request.session)

        logger.logRequest(urlRequest)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: urlRequest)
            logger.logResponse(response, data: data, error: nil)
        } catch {
            logger.logResponse(nil, data: nil, error: error)
            throw NetworkError.networkError(error)
        }

        try validateResponse(response)

        return try decodeResponse(data)
    }

    // MARK: - Private Helpers

    private func buildURLRequest<R: Request>(for request: R) throws -> URLRequest {
        var components = URLComponents(string: configuration.baseURL + request.path)

        if let query = request.query, !(query is EmptyQuery) {
            do {
                components?.queryItems = try query.asQueryItems(using: encoder)
            } catch {
                throw NetworkError.encodingError(error)
            }
        }

        guard let url = components?.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        // Default headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        // Configuration headers
        for (key, value) in configuration.defaultHeaders {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Request-specific headers
        if let headers = request.headers {
            for (key, value) in headers {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
        }

        // Body
        if let body = request.body, !(body is EmptyBody) {
            do {
                urlRequest.httpBody = try encoder.encode(body)
            } catch {
                logger.logError(.encodingError(error))
                throw NetworkError.encodingError(error)
            }
        }

        return urlRequest
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 400...499:
            throw NetworkError.clientError(statusCode: httpResponse.statusCode)
        case 500...599:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        default:
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.logError(.decodingError(error))
            throw NetworkError.decodingError(error)
        }
    }
}
