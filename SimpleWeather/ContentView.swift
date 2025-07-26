//
//  ContentView.swift
//  SimpleWeather
//
//  Created by Farley Caesar on 2025-05-26.
//

import SwiftUI
import CoreLocation
import SwiftData

struct ContentView: View {
    @State private var locationManager: LocationManager
    @StateObject private var weatherService = WeatherService()
    
    init() {
        do {
            let container = try ModelContainer(for: SavedLocation.self, CachedLocation.self)
            let locationCache = LocationCache(modelContext: container.mainContext)
            self._locationManager = State(wrappedValue: LocationManager(locationCache: locationCache))
        } catch {
            // Handle container initialization failure gracefully
            // Create a fallback LocationManager without persistence
            print("Failed to initialize model container: \(error)")
            self._locationManager = State(wrappedValue: LocationManager(locationCache: nil))
        }
    }
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousScenePhase: ScenePhase = .inactive
    @State private var errorMessage: String? = nil
    @State private var lastLocationUpdate = Date.distantPast
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            Group {
                if locationManager.isLoading && !locationManager.didUseCachedLocation {
                    loadingLocationView
                } else if weatherService.isLoadingCurrentWeather || weatherService.isLoadingForecast {
                    loadingWeatherView
                } else if let error = locationManager.locationError {
                    locationUnavailableView(error: error)
                } else if locationManager.location != nil {
                    if let current = weatherService.currentWeather {
                        weatherDisplayView(current: current, forecast: weatherService.dailyForecast)
                    } else if !weatherService.isLoadingCurrentWeather && !weatherService.isLoadingForecast {
                        HStack {
                            Spacer()
                            Button("Refresh Weather") {
                                Task {
                                    // Show loading immediately
                                    weatherService.isLoadingCurrentWeather = true
                                    weatherService.isLoadingForecast = true
                                    
                                    // Start a timer for minimum display time (2 seconds)
                                    let startTime = Date()
                                    
                                    // Trigger the refresh
                                    await fetchWeatherIfNeeded()
                                    
                                    // Calculate remaining time to reach 2 seconds
                                    let elapsed = Date().timeIntervalSince(startTime)
                                    let remaining = max(0, 2.0 - elapsed)
                                    
                                    // Wait if needed to ensure minimum display time
                                    if remaining > 0 {
                                        try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                                    }
                                    
                                    // Reset loading states
                                    weatherService.isLoadingCurrentWeather = false
                                    weatherService.isLoadingForecast = false
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    } else {
                        loadingWeatherView
                    }
                } else {
                    locationUnavailableView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: weatherService.isLoadingCurrentWeather)
            .animation(.easeInOut(duration: 0.3), value: locationManager.isLoading)
            .navigationTitle("SimpleWeather")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showingAbout = true
                        }
                    }) {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                            .accessibilityLabel("About")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAbout) {
            AboutView(showingAbout: $showingAbout)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
        }
        .onAppear {
            // If we have a cached location, use it immediately
            if locationManager.location != nil && (weatherService.currentWeather == nil || weatherService.dailyForecast == nil) {
                Task { await fetchWeatherIfNeeded() }
            }
        }
        .task(id: locationManager.location) {
            await fetchWeatherIfNeeded()
        }
        .refreshable {
            print("[ContentView] Refresh triggered.")
            locationManager.requestLocation()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase != .active {
                print("[ContentView] App became active, refreshing location and weather")
                locationManager.requestLocation()
            }
            previousScenePhase = newPhase
        }
    }
    
    private func fetchWeatherIfNeeded() async {
        guard let location = locationManager.location else { return }
        
        // Always fetch fresh weather data, but show cached data immediately if available
        if locationManager.didUseCachedLocation {
            // If we're using a cached location, fetch fresh data in the background
            // but don't wait for it to complete
            Task {
                await weatherService.fetchWeather(for: location)
            }
            return
        }
        
        // For non-cached locations, fetch fresh data and wait for it to complete
        await weatherService.fetchWeather(for: location)
        lastLocationUpdate = Date()
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

    private func locationUnavailableView(error: Error? = nil) -> some View {
        VStack(spacing: 20) {
            Text("Location Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
            
            if let error = error {
                Text(error.localizedDescription)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            } else {
                Text("We couldn't determine your location. Please make sure location services are enabled for this app.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .padding(.top, 10)
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
                CurrentWeatherView(
                    currentWeather: current, 
                    location: locationManager.location ?? CLLocation(latitude: 0, longitude: 0)
                )
                
                if let hourlyForecast = weatherService.hourlyForecast, !hourlyForecast.isEmpty {
                    HourlyWeatherView(hourlyForecasts: hourlyForecast)
                }
                
                if let forecast = forecast, !forecast.isEmpty {
                    ForecastView(dailyForecasts: forecast)
                        .padding(.top)
                } else {
                    Text("Forecast data is currently unavailable.")
                }
                // Add a refresh button for weather and location
                HStack {
                    Spacer()
                    Button("Refresh Weather") {
                        Task {
                            // Show loading UI
                            weatherService.isLoadingCurrentWeather = true
                            weatherService.isLoadingForecast = true

                            let startTime = Date()

                            // Request new location update
                            print("[ContentView] Manual refresh: Requesting new location")
                            locationManager.requestLocation()

                            // Wait for 1 second to allow location update
                            try? await Task.sleep(nanoseconds: 1_000_000_000)

                            if let location = locationManager.location {
                                print("[ContentView] Manual refresh: Fetching weather for updated location")
                                await weatherService.fetchWeather(for: location)
                            } else {
                                print("[ContentView] Manual refresh: Location still not available after update attempt")
                            }

                            // Enforce a 2-second minimum loading time
                            let elapsed = Date().timeIntervalSince(startTime)
                            let remaining = max(0, 2.0 - elapsed)
                            if remaining > 0 {
                                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
                            }

                            // Hide loading UI
                            weatherService.isLoadingCurrentWeather = false
                            weatherService.isLoadingForecast = false
                        }
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
                .padding(.vertical, 10)
            }
        }
    }
}

#Preview {
    ContentView()
}
