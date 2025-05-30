//
//  ContentView.swift
//  SimpleWeather
//
//  Created by Farley Caesar on 2025-05-26.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherService = WeatherService()
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousScenePhase: ScenePhase = .inactive
    @State private var showingAbout = false

    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                // Layer 1: Background Gradient (fills entire screen)
                backgroundGradient(for: weatherService.currentWeather?.conditionSymbolName)
                    .edgesIgnoringSafeArea(.all)

                // Layer 2: Main Content VStack (respects safe areas)
                VStack(spacing: 20) {
                    // Initial state: Request permission or show loading
                    if locationManager.authorizationStatus == .notDetermined {
                        requestLocationPermissionButton
                            .transition(.opacity.animation(.easeInOut))
                    } else if locationManager.authorizationStatus == .denied {
                        deniedLocationView
                            .transition(.opacity.animation(.easeInOut))
                    } else if locationManager.authorizationStatus == .restricted {
                        restrictedLocationView
                            .transition(.opacity.animation(.easeInOut))
                    } else if locationManager.isLoading {
                        loadingLocationView
                            .transition(.opacity.animation(.easeInOut))
                    } else if let locationError = locationManager.locationError,
                              locationManager.authorizationStatus != .denied,
                              locationManager.authorizationStatus != .restricted {
                        locationUnavailableView(error: locationError)
                            .transition(.opacity.animation(.easeInOut))
                    } else if locationManager.location != nil {
                        // Location is available, proceed with weather
                        if weatherService.isLoadingCurrentWeather || weatherService.isLoadingForecast {
                            loadingWeatherView
                                .transition(.opacity.animation(.easeInOut))
                        } else if let error = weatherService.weatherError {
                            weatherErrorView(error: error)
                                .transition(.opacity.animation(.easeInOut))
                        } else if let current = weatherService.currentWeather {
                            weatherDisplayView(current: current, forecast: weatherService.dailyForecast)
                                .transition(.opacity.animation(.easeInOut))
                        } else {
                            // Should not happen if logic is correct, but as a fallback
                            Text("Something went wrong. Please try again.")
                                .transition(.opacity.animation(.easeInOut))
                        }
                    } else {
                        // Fallback for any other unhandled state
                        Text("Unable to determine state. Please restart the app.")
                            .transition(.opacity.animation(.easeInOut))
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAbout = true
                    }) {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                            .accessibilityLabel("About")
                    }
                }
            }
            .sheet(isPresented: $showingAbout) {
                NavigationView {
                    AboutView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingAbout = false
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            // If authorized but no location yet (e.g. app restart), try to get it.
            // If .notDetermined, the UI above will prompt for permission.
            // If already denied/restricted, UI above handles it.
            if (locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways) && locationManager.location == nil {
                locationManager.requestLocation()
            }
        }
        .task(id: locationManager.location) {
            print("[ContentView] .task triggered. Location: \(String(describing: locationManager.location))")
            if let validLocation = locationManager.location {
                print("[ContentView] .task: Valid location found. Fetching weather for \(validLocation.coordinate).")
                await weatherService.fetchWeather(for: validLocation)
            } else {
                print("[ContentView] .task: Location is nil.")
                // Consider clearing weather data if location becomes nil and it's an intentional state
                // await weatherService.clearWeatherData() // Example if you add such a method
            }
        }
        .refreshable {
            print("[ContentView] Refresh triggered.")
            if let validLocation = locationManager.location {
                print("[ContentView] Refresh: Valid location found. Fetching weather for \(validLocation.coordinate).")
                await weatherService.fetchWeather(for: validLocation)
            } else {
                print("[ContentView] Refresh: Location is nil. Requesting location update.")
                // If location is nil on refresh, try to get it again.
                // This might be redundant if .task(id: locationManager.location) handles it,
                // but can be a fallback.
                locationManager.requestLocation()
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase != .active {
                print("[ContentView] App became active, refreshing location and weather")
                Task {
                    // Request a new location when app comes to foreground
                    locationManager.requestLocation()
                    
                    // Wait briefly for location update to complete
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    
                    // Then fetch weather with the updated location
                    if let location = locationManager.location {
                        print("[ContentView] App became active: Fetching weather for location")
                        await weatherService.fetchWeather(for: location)
                    }
                }
            }
            previousScenePhase = newPhase
        }
    }

    // MARK: - Background Gradient Helper
    private func backgroundGradient(for symbolName: String?) -> LinearGradient {
        guard let symbol = symbolName else {
            // Default gradient if no weather data
            return LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)]), startPoint: .top, endPoint: .bottom)
        }

        switch symbol {
        case "sun.max.fill", "sun.min.fill", "sun.haze.fill": // Sunny variations
            return LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.5), Color.orange.opacity(0.4)]), startPoint: .topLeading, endPoint: .bottomTrailing)
        case _ where symbol.contains("cloud.sun"): // Partly cloudy
            return LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.yellow.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        case _ where symbol.contains("cloud.rain"), _ where symbol.contains("drizzle"), _ where symbol.contains("heavyrain"): // Rainy variations
            return LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.indigo.opacity(0.6)]), startPoint: .top, endPoint: .bottom)
        case _ where symbol.contains("cloud.snow"), _ where symbol.contains("snow"), _ where symbol.contains("blizzard"): // Snowy variations
            return LinearGradient(gradient: Gradient(colors: [Color.cyan.opacity(0.4), Color.white.opacity(0.2)]), startPoint: .top, endPoint: .bottom)
        case _ where symbol.contains("cloud.fog"), _ where symbol.contains("fog"): // Foggy
            return LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
        case _ where symbol.contains("cloud"): // General cloudy
            return LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.gray.opacity(0.4)]), startPoint: .top, endPoint: .bottom)
        case "wind":
            return LinearGradient(gradient: Gradient(colors: [Color.teal.opacity(0.4), Color.gray.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        // Consider night variations if time of day is available
        // case _ where symbol.contains("moon"), _ where symbol.contains("night"): // Night clear/cloudy
        //     return LinearGradient(gradient: Gradient(colors: [Color.indigo.opacity(0.7), Color.black.opacity(0.7)]), startPoint: .top, endPoint: .bottom)
        default: // Fallback for other symbols
            return LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.4), Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom)
        }
    }

    // MARK: - Subviews for different states

    private var requestLocationPermissionButton: some View {
        VStack(spacing: 20) {
            Text("Welcome to SimpleWeather!")
                .font(.title)
            Text("Please grant location access to see the weather for your current location.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("Grant Location Access") {
                locationManager.requestLocationAccess()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var deniedLocationView: some View {
        VStack(spacing: 20) {
            Text("Location Access Denied")
                .font(.title2)
                .fontWeight(.semibold)
            Text("To show you the weather, SimpleWeather needs access to your location. Please enable location services in Settings.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var restrictedLocationView: some View {
        VStack(spacing: 20) {
            Text("Location Access Restricted")
                .font(.title2)
            Text("SimpleWeather needs your location to provide weather information. Please enable location services in Settings.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }

    private var loadingLocationView: some View {
        VStack {
            Spacer()
            ProgressView("Fetching your location...")
                .scaleEffect(1.5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func locationUnavailableView(error: Error) -> some View {
        VStack(spacing: 20) {
            Text("Location Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Could not determine your location. Please check your connection or try again. Error: \(error.localizedDescription)")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Try Again") {
                locationManager.requestLocation() // Attempt to get location again
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var loadingWeatherView: some View {
        VStack {
            Spacer()
            ProgressView("Fetching weather data...")
                .scaleEffect(1.5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func weatherErrorView(error: Error) -> some View {
        VStack(spacing: 20) {
            Text("Failed to Load Weather")
                .font(.title2)
                .fontWeight(.semibold)
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Retry") {
                if let location = locationManager.location {
                    Task {
                        await weatherService.fetchWeather(for: location)
                    }
                } else {
                    // If location is nil, try to request it again.
                    // The UI should ideally reflect this state change too.
                    locationManager.requestLocation()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func weatherDisplayView(current: CurrentWeather, forecast: [DailyForecast]?) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CurrentWeatherView(currentWeather: current, location: locationManager.location)
                if let forecast = forecast, !forecast.isEmpty {
                    ForecastView(dailyForecasts: forecast)
                        .padding(.top)
                } else {
                    Text("Forecast data is currently unavailable.")
                }
                // Add a refresh button for weather and location
                Button("Refresh Weather") {
                    Task {
                        // First request a new location update
                        print("[ContentView] Manual refresh: Requesting new location")
                        locationManager.requestLocation()
                        
                        // Wait briefly for location update to complete
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        
                        // Then fetch weather with the (potentially) updated location
                        if let location = locationManager.location {
                            print("[ContentView] Manual refresh: Fetching weather for updated location")
                            await weatherService.fetchWeather(for: location)
                        } else {
                            print("[ContentView] Manual refresh: Location still not available after update attempt")
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

#Preview {
    ContentView()
}
