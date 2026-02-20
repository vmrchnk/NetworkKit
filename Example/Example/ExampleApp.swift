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
            TabView {
                ContentView()
                    .tabItem {
                        Label("Weather", systemImage: "cloud.sun")
                    }

                DownloadDemoView()
                    .tabItem {
                        Label("Download", systemImage: "arrow.down.circle")
                    }
            }
        }
    }
}
