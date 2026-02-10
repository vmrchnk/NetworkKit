//
//  ContentView.swift
//  Example
//

import SwiftUI
import NetworkKit

struct ContentView: View {
    @State private var searchText = ""
    @State private var cities: [GeocodingResponse.City] = []
    @State private var selectedCity: GeocodingResponse.City?
    @State private var weather: WeatherResponse?
    @State private var isSearching = false
    @State private var isLoadingWeather = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Field
                searchField

                if let weather = weather, let city = selectedCity {
                    // Weather Card
                    weatherCard(city: city, weather: weather)
                        .padding()
                }

                // City List
                cityList

                Spacer()
            }
            .navigationTitle("Weather")
        }
    }

    // MARK: - Search Field

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search city...", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onSubmit {
                    Task { await searchCities() }
                }

            if isSearching {
                ProgressView()
                    .scaleEffect(0.8)
            } else if !searchText.isEmpty {
                Button {
                    searchText = ""
                    cities = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }

    // MARK: - Weather Card

    private func weatherCard(city: GeocodingResponse.City, weather: WeatherResponse) -> some View {
        VStack(spacing: 16) {
            // City Name
            Text(city.name)
                .font(.title2.bold())

            Text(city.country)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Weather Icon & Temperature
            HStack(spacing: 20) {
                Image(systemName: weather.currentWeather.weatherIcon)
                    .font(.system(size: 60))
                    .symbolRenderingMode(.multicolor)

                VStack(alignment: .leading) {
                    Text("\(Int(weather.currentWeather.temperature))°C")
                        .font(.system(size: 48, weight: .thin))

                    Text(weather.currentWeather.weatherDescription)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            // Wind Info
            HStack {
                Image(systemName: "wind")
                Text("\(Int(weather.currentWeather.windspeed)) km/h")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - City List

    private var cityList: some View {
        Group {
            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .padding()
            } else if cities.isEmpty && !searchText.isEmpty && !isSearching {
                ContentUnavailableView(
                    "No cities found",
                    systemImage: "mappin.slash",
                    description: Text("Try a different search term")
                )
            } else {
                List(cities) { city in
                    Button {
                        Task { await selectCity(city) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(city.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                Text([city.admin1, city.country].compactMap { $0 }.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if isLoadingWeather && selectedCity?.id == city.id {
                                ProgressView()
                            } else if selectedCity?.id == city.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func searchCities() async {
        guard !searchText.isEmpty else { return }

        isSearching = true
        errorMessage = nil

        do {
            let request = SearchCitiesRequest(name: searchText, count: 10)
            let response = try await request.execute()
            cities = response.results ?? []
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }

        isSearching = false
    }

    private func selectCity(_ city: GeocodingResponse.City) async {
        selectedCity = city
        isLoadingWeather = true
        errorMessage = nil

        do {
            let request = GetWeatherRequest(
                latitude: city.latitude,
                longitude: city.longitude
            )
            weather = try await request.execute()
        } catch {
            errorMessage = "Failed to load weather: \(error.localizedDescription)"
        }

        isLoadingWeather = false
    }
}

#Preview {
    ContentView()
}
