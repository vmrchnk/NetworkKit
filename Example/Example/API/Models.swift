//
//  Models.swift
//  Example
//

import Foundation

// MARK: - Weather Response

nonisolated struct WeatherResponse: Decodable, Sendable {
    let latitude: Double
    let longitude: Double
    let currentWeather: CurrentWeather

    struct CurrentWeather: Decodable, Sendable {
        let temperature: Double
        let windspeed: Double
        let winddirection: Double
        let weathercode: Int
        let isDay: Int
        let time: String
    }
}

// MARK: - Geocoding Response

nonisolated struct GeocodingResponse: Decodable, Sendable {
    let results: [City]?

    struct City: Decodable, Sendable, Identifiable {
        let id: Int
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String
        let admin1: String?
    }
}

// MARK: - Weather Code Helper

extension WeatherResponse.CurrentWeather {
    var weatherDescription: String {
        switch weathercode {
        case 0: return "Clear sky"
        case 1, 2, 3: return "Partly cloudy"
        case 45, 48: return "Foggy"
        case 51, 53, 55: return "Drizzle"
        case 61, 63, 65: return "Rain"
        case 66, 67: return "Freezing rain"
        case 71, 73, 75: return "Snow"
        case 77: return "Snow grains"
        case 80, 81, 82: return "Rain showers"
        case 85, 86: return "Snow showers"
        case 95: return "Thunderstorm"
        case 96, 99: return "Thunderstorm with hail"
        default: return "Unknown"
        }
    }

    var weatherIcon: String {
        let day = isDay == 1
        switch weathercode {
        case 0: return day ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2, 3: return day ? "cloud.sun.fill" : "cloud.moon.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51, 53, 55, 61, 63, 65: return "cloud.rain.fill"
        case 66, 67: return "cloud.sleet.fill"
        case 71, 73, 75, 77, 85, 86: return "cloud.snow.fill"
        case 80, 81, 82: return "cloud.heavyrain.fill"
        case 95, 96, 99: return "cloud.bolt.rain.fill"
        default: return "questionmark.circle"
        }
    }
}
