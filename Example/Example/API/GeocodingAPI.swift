//
//  GeocodingAPI.swift
//  Example
//

import Foundation
import NetworkKit

// MARK: - Geocoding Client

nonisolated enum GeocodingAPI {
    static let client: NetworkClient = {
        let config = NetworkClientConfiguration(
            baseURL: "https://geocoding-api.open-meteo.com/v1"
        )
        return NetworkClient(configuration: config)
    }()
}

// MARK: - Search Cities

nonisolated struct SearchCitiesRequest: Request {
    typealias Response = GeocodingResponse

    let name: String
    let count: Int

    var path: String { "/search" }
    var method: HTTPMethod { .get }
    var query: Query? { Query(name: name, count: count) }

    struct Query: Encodable, Sendable {
        let name: String
        let count: Int
    }

    func execute() async throws -> Response {
        try await GeocodingAPI.client.execute(self)
    }
}
