import Foundation
import Testing
@testable import NetworkKit

// MARK: - Request Tests

@Suite("Request Tests")
struct RequestTests {

    @Test("Request without body has nil body")
    func requestWithoutBody() {
        struct GetUser: Request {
            typealias Response = String
            var path: String { "/users/1" }
            var method: HTTPMethod { .get }
        }

        let request = GetUser()
        #expect(request.body == nil)
        #expect(request.path == "/users/1")
        #expect(request.method == .get)
    }

    @Test("Request with body contains body data")
    func requestWithBody() {
        struct CreateUser: Request {
            struct Body: Encodable {
                let name: String
                let email: String
            }
            typealias Response = String

            let body: Body?
            var path: String { "/users" }
            var method: HTTPMethod { .post }
        }

        let request = CreateUser(body: .init(name: "John", email: "john@test.com"))
        #expect(request.body != nil)
        #expect(request.body?.name == "John")
        #expect(request.body?.email == "john@test.com")
        #expect(request.method == .post)
    }

    @Test("Request with query encodes query items")
    func requestWithQuery() throws {
        struct SearchUsers: Request {
            struct Query: Encodable {
                let name: String
                let limit: Int
            }
            typealias Response = [String]

            let query: Query?
            var path: String { "/users/search" }
            var method: HTTPMethod { .get }
        }

        let request = SearchUsers(query: .init(name: "John", limit: 10))
        #expect(request.query != nil)
        #expect(request.query?.name == "John")
        #expect(request.query?.limit == 10)

        let queryItems = try request.query?.asQueryItems()
        #expect(queryItems?.count == 2)
    }

    @Test("Request uses nil baseURL by default")
    func requestUsesNilBaseURLByDefault() {
        struct SimpleRequest: Request {
            typealias Response = String
            var path: String { "/test" }
            var method: HTTPMethod { .get }
        }

        let request = SimpleRequest()
        #expect(request.baseURL == nil)
    }

    @Test("Request can specify custom baseURL")
    func requestWithCustomBaseURL() {
        struct ExternalAPIRequest: Request {
            typealias Response = String
            var path: String { "/data" }
            var method: HTTPMethod { .get }
            var baseURL: String? { "https://external-api.com" }
        }

        let request = ExternalAPIRequest()
        #expect(request.baseURL == "https://external-api.com")
    }
}

// MARK: - Session Provider Tests

@Suite("SessionProvider Tests")
struct SessionProviderTests {

    @Test("DefaultSession has correct identifier")
    func defaultSessionProvider() {
        let session = DefaultSession.shared

        #expect(session.identifier == "com.networkkit.default")

        let config = session.makeConfiguration()
        #expect(config.identifier == nil)
    }

    @Test("BackgroundSession has correct identifier and configuration")
    func backgroundSessionProvider() {
        let session = BackgroundSession(identifier: "com.app.upload")

        #expect(session.identifier == "com.app.upload")

        let config = session.makeConfiguration()
        #expect(config.identifier == "com.app.upload")
    }

    @Test("EphemeralSession creates valid configuration")
    func ephemeralSessionProvider() {
        let session = EphemeralSession.shared

        #expect(session.identifier == "com.networkkit.ephemeral")

        // Verify configuration is created successfully
        _ = session.makeConfiguration()
    }

    @Test("Request uses DefaultSession by default")
    func requestUsesDefaultSession() {
        struct SimpleRequest: Request {
            typealias Response = String
            var path: String { "/test" }
            var method: HTTPMethod { .get }
        }

        let request = SimpleRequest()
        #expect(request.session.identifier == "com.networkkit.default")
    }

    @Test("Request can use BackgroundSession")
    func requestUsesBackgroundSession() {
        struct UploadRequest: Request {
            typealias Response = String
            typealias Session = BackgroundSession

            var path: String { "/upload" }
            var method: HTTPMethod { .post }
            var session: BackgroundSession { BackgroundSession(identifier: "com.app.upload") }
        }

        let request = UploadRequest()
        #expect(request.session.identifier == "com.app.upload")
    }

    @Test("Request can use EphemeralSession")
    func requestUsesEphemeralSession() {
        struct PrivateRequest: Request {
            typealias Response = String
            typealias Session = EphemeralSession

            var path: String { "/private" }
            var method: HTTPMethod { .get }
            var session: EphemeralSession { .shared }
        }

        let request = PrivateRequest()
        #expect(request.session.identifier == "com.networkkit.ephemeral")
    }

    @Test("Custom SessionProvider works correctly")
    func customSessionProvider() {
        struct LowPrioritySession: SessionProvider {
            var identifier: String { "com.app.low-priority" }

            func makeConfiguration() -> URLSessionConfiguration {
                let config = URLSessionConfiguration.default
                config.allowsCellularAccess = false
                config.networkServiceType = .background
                return config
            }
        }

        struct SyncRequest: Request {
            typealias Response = String
            typealias Session = LowPrioritySession

            var path: String { "/sync" }
            var method: HTTPMethod { .post }
            var session: LowPrioritySession { LowPrioritySession() }
        }

        let request = SyncRequest()
        #expect(request.session.identifier == "com.app.low-priority")

        let config = request.session.makeConfiguration()
        #expect(config.allowsCellularAccess == false)
        #expect(config.networkServiceType == .background)
    }

    @Test("SessionProvider is Hashable")
    func sessionProviderHashable() {
        let session1 = BackgroundSession(identifier: "com.app.upload")
        let session2 = BackgroundSession(identifier: "com.app.upload")
        let session3 = BackgroundSession(identifier: "com.app.download")

        #expect(session1 == session2)
        #expect(session1 != session3)

        var set: Set<BackgroundSession> = []
        set.insert(session1)
        set.insert(session2)
        #expect(set.count == 1)
    }
}

// MARK: - Progress Tests

@Suite("RequestProgress Tests")
struct RequestProgressTests {

    @Test("RequestProgress holds progress value")
    func progressHoldsValue() {
        let progress: RequestProgress<String> = .progress(0.5)

        if case .progress(let value) = progress {
            #expect(value == 0.5)
        } else {
            Issue.record("Expected .progress case")
        }
    }

    @Test("RequestProgress holds completed value")
    func progressHoldsCompleted() {
        let progress: RequestProgress<String> = .completed("result")

        if case .completed(let value) = progress {
            #expect(value == "result")
        } else {
            Issue.record("Expected .completed case")
        }
    }

    @Test("RequestProgress is Sendable")
    func progressIsSendable() async {
        let progress: RequestProgress<Int> = .progress(0.75)

        await Task {
            if case .progress(let value) = progress {
                #expect(value == 0.75)
            }
        }.value
    }
}

// MARK: - Integration Tests

@Suite("Integration Tests")
struct IntegrationTests {

    @Test("Execute uses shared client")
    func executeUsesSharedClient() async throws {
        NetworkClient.shared = NetworkClient(
            configuration: .init(baseURL: "https://httpbin.org")
        )

        struct GetIP: Request {
            typealias Response = IPResponse
            var path: String { "/ip" }
            var method: HTTPMethod { .get }
        }

        struct IPResponse: Decodable {
            let origin: String
        }

        let response = try await GetIP().execute()
        #expect(!response.origin.isEmpty)
    }

    @Test("Execute with EphemeralSession works")
    func executeWithEphemeralSession() async throws {
        NetworkClient.shared = NetworkClient(
            configuration: .init(baseURL: "https://httpbin.org")
        )

        struct EphemeralRequest: Request {
            typealias Response = IPResponse
            typealias Session = EphemeralSession

            var path: String { "/ip" }
            var method: HTTPMethod { .get }
            var session: EphemeralSession { .shared }
        }

        struct IPResponse: Decodable {
            let origin: String
        }

        let response = try await EphemeralRequest().execute()
        #expect(!response.origin.isEmpty)
    }

    @Test("Download with progress tracks progress and saves file")
    func downloadWithProgress() async throws {
        NetworkClient.shared = NetworkClient(
            configuration: .init(baseURL: "https://httpbin.org")
        )

        struct DownloadRequest: Request {
            typealias Response = Data
            var path: String { "/bytes/1024" }
            var method: HTTPMethod { .get }
        }

        let tempDir = FileManager.default.temporaryDirectory
        let destination = tempDir.appendingPathComponent("test_download_\(UUID().uuidString).bin")

        defer {
            try? FileManager.default.removeItem(at: destination)
        }

        var progressValues: [Double] = []
        var completedURL: URL?

        for try await event in DownloadRequest().download(to: destination) {
            switch event {
            case .progress(let value):
                progressValues.append(value)
            case .completed(let url):
                completedURL = url
            }
        }

        #expect(completedURL == destination)
        #expect(FileManager.default.fileExists(atPath: destination.path))

        let fileData = try Data(contentsOf: destination)
        #expect(fileData.count == 1024)
    }

    @Test("Upload with progress tracks progress and returns response")
    func uploadWithProgress() async throws {
        NetworkClient.shared = NetworkClient(
            configuration: .init(baseURL: "https://httpbin.org")
        )

        struct UploadResponse: Decodable {
            let data: String
        }

        struct UploadRequest: Request {
            typealias Response = UploadResponse
            var path: String { "/post" }
            var method: HTTPMethod { .post }
        }

        // Create temp file to upload
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("test_upload_\(UUID().uuidString).txt")
        let testData = Data(repeating: 65, count: 1024) // 1KB of 'A's
        try testData.write(to: fileURL)

        defer {
            try? FileManager.default.removeItem(at: fileURL)
        }

        var progressValues: [Double] = []
        var response: UploadResponse?

        for try await event in UploadRequest().upload(from: fileURL) {
            switch event {
            case .progress(let value):
                progressValues.append(value)
            case .completed(let result):
                response = result
            }
        }

        #expect(response != nil)
        #expect(!progressValues.isEmpty)
    }

}
