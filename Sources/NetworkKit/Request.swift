import Foundation

// MARK: - Empty Types

public struct EmptyBody: Encodable, Sendable {
    public init() {}
}

public struct EmptyQuery: Encodable, Sendable {
    public init() {}
}

// MARK: - Request Protocol

public protocol Request: Sendable {
    associatedtype Response: Decodable & Sendable
    associatedtype Body: Encodable & Sendable = EmptyBody
    associatedtype Query: Encodable & Sendable = EmptyQuery
    associatedtype Session: SessionProvider = DefaultSession

    var body: Body? { get }
    var query: Query? { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var session: Session { get }
    var baseURL: String? { get }
}

// MARK: - Default Implementations

public extension Request {
    var body: Body? { nil }
    var query: Query? { nil }
    var headers: [String: String]? { nil }
    var baseURL: String? { nil }

    func execute() async throws -> Response {
        try await NetworkClient.shared.execute(self)
    }
}

public extension Request where Session == DefaultSession {
    var session: DefaultSession { .shared }
}

// MARK: - Query Items Encoding

public extension Encodable {
    func asQueryItems(using encoder: JSONEncoder = JSONEncoder()) throws -> [URLQueryItem] {
        let data = try encoder.encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        return dictionary.compactMap { key, value in
            if let array = value as? [Any] {
                // Handle arrays by creating multiple items with same key
                return array.map { URLQueryItem(name: key, value: "\($0)") }
            }
            return [URLQueryItem(name: key, value: "\(value)")]
        }.flatMap { $0 }
    }
}
