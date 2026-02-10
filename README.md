# NetworkKit

A lightweight, type-safe networking library for Swift using the **Request Object Pattern**.

## Pattern Overview

The Request Object Pattern (also known as Type-Safe Request Pattern or Endpoint-as-Type) provides compile-time type safety for API requests by representing each endpoint as a distinct Swift type.

### Key Benefits

- **Type Safety**: Response types are known at compile time
- **Self-Documenting**: Each request struct describes its endpoint
- **Testable**: Easy to mock and test
- **Maintainable**: Changes to API contracts are caught by the compiler

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-username/NetworkKit.git", from: "1.0.0")
]
```

Or add via Xcode: File → Add Package Dependencies

## Usage

### 1. Define Your Requests

```swift
import NetworkKit

// Simple GET request
struct GetUser: Request {
    typealias Response = User

    let userId: String
    var path: String { "/users/\(userId)" }
    var method: HTTPMethod { .get }
}

// POST request with body
struct CreatePost: Request {
    typealias Response = Post
    typealias Body = CreatePostBody

    let body: Body?
    var path: String { "/posts" }
    var method: HTTPMethod { .post }
}

struct CreatePostBody: Encodable {
    let title: String
    let content: String
}

// GET request with query parameters
struct SearchUsers: Request {
    typealias Response = [User]
    typealias Query = SearchQuery

    let query: Query?
    var path: String { "/users/search" }
    var method: HTTPMethod { .get }
}

struct SearchQuery: Encodable {
    let name: String
    let limit: Int
}
```

### 2. Create a Network Client

```swift
let client = NetworkClient(
    configuration: NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        defaultHeaders: ["Authorization": "Bearer \(token)"]
    )
)
```

### 3. Execute Requests

```swift
// Async/await
let user = try await client.execute(GetUser(userId: "123"))

// With query
let users = try await client.execute(
    SearchUsers(query: .init(name: "John", limit: 10))
)

// With body
let post = try await client.execute(
    CreatePost(body: .init(title: "Hello", content: "World"))
)
```

## Configuration

### NetworkClientConfiguration

```swift
NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    timeoutInterval: 30,           // Request timeout (seconds)
    resourceTimeout: 300,          // Resource timeout (seconds)
    waitsForConnectivity: true,    // Wait for network
    defaultHeaders: [:]            // Headers for all requests
)
```

### Custom Encoder/Decoder

```swift
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .formatted(customFormatter)

let client = NetworkClient(
    configuration: config,
    decoder: decoder,
    encoder: customEncoder
)
```

### Logging

```swift
// Default logger (enabled)
let client = NetworkClient(configuration: config)

// Custom logger
let logger = NetworkLogger(
    subsystem: "com.myapp",
    category: "API",
    isEnabled: !isProduction
)
let client = NetworkClient(configuration: config, logger: logger)

// Silent logger (no output)
let client = NetworkClient(configuration: config, logger: SilentNetworkLogger())
```

## Error Handling

```swift
do {
    let user = try await client.execute(GetUser(userId: "123"))
} catch let error as NetworkError {
    switch error {
    case .unauthorized:
        // Handle 401
    case .notFound:
        // Handle 404
    case .serverError(let code):
        // Handle 5xx
    case .decodingError(let underlying):
        // Handle JSON parsing error
    default:
        break
    }

    // Check if retryable
    if error.isRetryable {
        // Implement retry logic
    }
}
```

## Organization Pattern

Recommended way to organize requests in your app:

```swift
// Requests.swift
enum API {
    enum Users {
        struct Get: Request { ... }
        struct Create: Request { ... }
        struct Update: Request { ... }
    }

    enum Posts {
        struct List: Request { ... }
        struct Get: Request { ... }
    }
}

// Usage
let user = try await client.execute(API.Users.Get(id: "123"))
```

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+

## License

MIT
