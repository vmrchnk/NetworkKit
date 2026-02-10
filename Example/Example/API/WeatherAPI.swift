//
//  WeatherAPI.swift
//  Example
//

import Foundation
import NetworkKit

// MARK: - Weather Client Configuration

nonisolated enum WeatherAPI {
    static let configuration = NetworkClientConfiguration(
        baseURL: "https://api.open-meteo.com/v1"
    )
}

// MARK: - Get Current Weather

nonisolated struct GetWeatherRequest: Request {
    typealias Response = WeatherResponse

    let latitude: Double
    let longitude: Double

    var path: String { "/forecast" }
    var method: HTTPMethod { .get }
    var query: Query? {
        Query(
            latitude: latitude,
            longitude: longitude,
            currentWeather: true
        )
    }

    struct Query: Encodable, Sendable {
        let latitude: Double
        let longitude: Double
        let currentWeather: Bool
    }
}
