import XCTest
@testable import NetworkKit

final class NetworkKitTests: XCTestCase {

    // MARK: - Request Without Body

    func testRequestWithoutBody() {
        struct GetUser: Request {
            typealias Response = String
            var path: String { "/users/1" }
            var method: HTTPMethod { .get }
        }

        let request = GetUser()
        XCTAssertNil(request.body)
        XCTAssertEqual(request.path, "/users/1")
        XCTAssertEqual(request.method, .get)
    }

    // MARK: - Request With Body

    func testRequestWithBody() {
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
        XCTAssertNotNil(request.body)
        XCTAssertEqual(request.body?.name, "John")
        XCTAssertEqual(request.body?.email, "john@test.com")
        XCTAssertEqual(request.method, .post)
    }

    // MARK: - Request With Query

    func testRequestWithQuery() throws {
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
        XCTAssertNotNil(request.query)
        XCTAssertEqual(request.query?.name, "John")
        XCTAssertEqual(request.query?.limit, 10)

        let queryItems = try request.query?.asQueryItems()
        XCTAssertEqual(queryItems?.count, 2)
    }

    // MARK: - Execute

    func testExecuteUsesSharedClient() async {
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

        do {
            let response = try await GetIP().execute()
            XCTAssertFalse(response.origin.isEmpty)
        } catch {
            XCTFail("Request failed: \(error)")
        }
    }
}
