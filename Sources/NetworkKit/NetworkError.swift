import Foundation

public enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case clientError(statusCode: Int)
    case serverError(statusCode: Int)
    case decodingError(Error)
    case encodingError(Error)
    case networkError(Error)
    case unknown

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .clientError(let statusCode):
            return "Client error with status code: \(statusCode)"
        case .serverError(let statusCode):
            return "Server error with status code: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown:
            return "Unknown error occurred"
        }
    }

    public var statusCode: Int? {
        switch self {
        case .unauthorized: return 401
        case .forbidden: return 403
        case .notFound: return 404
        case .clientError(let code): return code
        case .serverError(let code): return code
        default: return nil
        }
    }

    public var isRetryable: Bool {
        switch self {
        case .serverError, .networkError:
            return true
        default:
            return false
        }
    }
}
