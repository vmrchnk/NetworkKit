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
    .package(url: "https://github.com/your-username/NetworkKit.git", from: "0.1.0")
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

### 2. Configure Network Client

```swift
// At app startup (e.g., in AppDelegate or @main App)
NetworkClient.shared = NetworkClient(
    configuration: NetworkClientConfiguration(
        baseURL: "https://api.example.com",
        defaultHeaders: ["Authorization": "Bearer \(token)"]
    )
)
```

### 3. Execute Requests

```swift
// Simple request
let user = try await GetUser(userId: "123").execute()

// With query
let users = try await SearchUsers(query: .init(name: "John", limit: 10)).execute()

// With body
let post = try await CreatePost(body: .init(title: "Hello", content: "World")).execute()
```

### 4. Download with Progress

```swift
struct DownloadFileRequest: Request {
    typealias Response = Data

    let fileURL: String
    var baseURL: String? { "" }
    var path: String { fileURL }
    var method: HTTPMethod { .get }
}

let request = DownloadFileRequest(fileURL: "https://example.com/file.mp4")
let destination = FileManager.default.temporaryDirectory
    .appendingPathComponent("video.mp4")

for try await event in request.download(to: destination) {
    switch event {
    case .progress(let progress):
        print("Downloaded: \(Int(progress * 100))%")
    case .completed(let url):
        print("Saved to: \(url)")
    }
}
```

### 5. Upload with Progress

```swift
struct UploadFileRequest: Request {
    typealias Response = UploadResponse

    var path: String { "/upload" }
    var method: HTTPMethod { .post }
}

let fileURL = URL(fileURLWithPath: "/path/to/file.pdf")

for try await event in UploadFileRequest().upload(from: fileURL) {
    switch event {
    case .progress(let progress):
        print("Uploaded: \(Int(progress * 100))%")
    case .completed(let response):
        print("Upload complete: \(response)")
    }
}
```

## Session Providers

NetworkKit supports different URLSession configurations for various use cases:

### DefaultSession (default)

Standard session for most API calls:

```swift
struct GetUser: Request {
    // Uses DefaultSession automatically
    typealias Response = User
    var path: String { "/users/1" }
    var method: HTTPMethod { .get }
}
```

### EphemeralSession

For private/sensitive requests (no caching, no cookies stored):

```swift
struct PrivateRequest: Request {
    typealias Response = SensitiveData
    typealias Session = EphemeralSession

    var path: String { "/private" }
    var method: HTTPMethod { .get }
    var session: EphemeralSession { .shared }
}
```

### BackgroundSession

For uploads/downloads that continue when app is backgrounded:

```swift
struct LargeUpload: Request {
    typealias Response = UploadResult
    typealias Session = BackgroundSession

    var path: String { "/upload" }
    var method: HTTPMethod { .post }
    var session: BackgroundSession {
        BackgroundSession(identifier: "com.myapp.upload")
    }
}
```

### Custom SessionProvider

```swift
struct LowPrioritySession: SessionProvider {
    var identifier: String { "com.myapp.low-priority" }

    func makeConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.allowsCellularAccess = false
        config.networkServiceType = .background
        return config
    }
}
```

## Custom Base URL

Override the base URL for specific requests (useful for multiple API endpoints):

```swift
struct ExternalAPIRequest: Request {
    typealias Response = ExternalData

    var path: String { "/data" }
    var method: HTTPMethod { .get }
    var baseURL: String? { "https://external-api.com" }
}
```

## Configuration

### NetworkClientConfiguration

```swift
NetworkClientConfiguration(
    baseURL: "https://api.example.com",
    defaultHeaders: ["Authorization": "Bearer \(token)"]
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
    let user = try await GetUser(userId: "123").execute()
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
let user = try await API.Users.Get(id: "123").execute()
```

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 5.9+

## License

MIT
