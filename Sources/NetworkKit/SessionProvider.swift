import Foundation

// MARK: - Session Provider Protocol

public protocol SessionProvider: Sendable, Hashable {
    var identifier: String { get }
    func makeConfiguration() -> URLSessionConfiguration
}

// MARK: - Default Session

public struct DefaultSession: SessionProvider {
    public static let shared = DefaultSession()

    public init() {}

    public var identifier: String { "com.networkkit.default" }

    public func makeConfiguration() -> URLSessionConfiguration {
        .default
    }
}

// MARK: - Background Session

public struct BackgroundSession: SessionProvider {
    public let identifier: String

    public init(identifier: String) {
        self.identifier = identifier
    }

    public func makeConfiguration() -> URLSessionConfiguration {
        .background(withIdentifier: identifier)
    }
}

// MARK: - Ephemeral Session

public struct EphemeralSession: SessionProvider {
    public static let shared = EphemeralSession()

    public init() {}

    public var identifier: String { "com.networkkit.ephemeral" }

    public func makeConfiguration() -> URLSessionConfiguration {
        .ephemeral
    }
}
