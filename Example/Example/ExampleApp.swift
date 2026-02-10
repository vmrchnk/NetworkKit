//
//  ExampleApp.swift
//  Example
//

import SwiftUI
import NetworkKit

@main
struct ExampleApp: App {

    init() {
        // Configure NetworkClient for Weather API
        NetworkClient.shared = NetworkClient(
            configuration: WeatherAPI.configuration
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
