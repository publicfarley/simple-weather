import SwiftUI
import CoreLocation

struct WeatherContentView: View {
    let location: SavedLocation
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var weatherService: WeatherService
    @Binding var showingAbout: Bool
    
    @Environment(\.scenePhase) private var scenePhase
    @State private var previousScenePhase: ScenePhase = .inactive
    @State private var lastRefresh = Date.distantPast
    
    var body: some View {
        Group {
            if showingAbout {
                AboutView(showingAbout: $showingAbout)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingAbout = false
                            }
                        }
                    }
            } else if location.isCurrentLocation && locationManager.isLoading && !locationManager.didUseCachedLocation {
                loadingLocationView
            } else if weatherService.isLoadingCurrentWeather || weatherService.isLoadingForecast {
                loadingWeatherView
            } else if location.isCurrentLocation, let error = locationManager.locationError {
                locationUnavailableView(error: error)
            } else {
                if let current = weatherService.currentWeather {
                    weatherDisplayView(current: current, forecast: weatherService.dailyForecast)
                } else if !weatherService.isLoadingCurrentWeather && !weatherService.isLoadingForecast {
                    noWeatherDataView
                } else {
                    loadingWeatherView
                }
            }
        }
        .onAppear {
            Task {
                await fetchWeatherIfNeeded()
            }
        }
        .task(id: location.id) {
            await fetchWeatherIfNeeded()
        }
        .refreshable {
            await refreshWeather()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active && oldPhase != .active {
                Task {
                    await refreshWeather()
                }
            }
            previousScenePhase = newPhase
        }
        .toolbar {
            if !showingAbout {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAbout = true }) {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                            .accessibilityLabel("About")
                    }
                }
            }
        }
    }
    
    private func fetchWeatherIfNeeded() async {
        // Check for cached data first
        if let cachedData = weatherService.getCachedWeather(for: location) {
            weatherService.currentWeather = cachedData.currentWeather
            weatherService.dailyForecast = cachedData.dailyForecast
            weatherService.hourlyForecast = cachedData.hourlyForecast
        }
        
        // For current location, update coordinates if needed
        if location.isCurrentLocation, let currentLocation = locationManager.location {
            let updatedLocation = SavedLocation(
                name: location.name,
                coordinate: currentLocation.coordinate,
                isCurrentLocation: true
            )
            await weatherService.fetchWeather(for: updatedLocation)
        } else {
            await weatherService.fetchWeather(for: location)
        }
    }
    
    private func refreshWeather() async {
        if location.isCurrentLocation {
            locationManager.requestLocation()
            // Wait briefly for location update
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        
        await fetchWeatherIfNeeded()
        lastRefresh = Date()
    }
    
    // MARK: - Subviews
    
    private var loadingLocationView: some View {
        VStack {
            Spacer()
            ProgressView("Fetching your location...")
                .scaleEffect(1.5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    private var noWeatherDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cloud.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Weather Data")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Unable to load weather information for this location.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Retry") {
                Task {
                    await refreshWeather()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
    
    private func weatherDisplayView(current: CurrentWeather, forecast: [DailyForecast]?) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CurrentWeatherView(
                    currentWeather: current,
                    location: location.isCurrentLocation ? 
                        (locationManager.location ?? CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)) :
                        CLLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                )
                
                if let hourlyForecast = weatherService.hourlyForecast, !hourlyForecast.isEmpty {
                    HourlyWeatherView(hourlyForecasts: hourlyForecast)
                }
                
                if let forecast = forecast, !forecast.isEmpty {
                    ForecastView(dailyForecasts: forecast)
                        .padding(.top)
                } else {
                    Text("Forecast data is currently unavailable.")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // Refresh button
                HStack {
                    Spacer()
                    Button("Refresh Weather") {
                        Task {
                            await refreshWeather()
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
    let sampleLocation = SavedLocation(
        name: "New York, NY, United States",
        coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    )
    
    return WeatherContentView(
        location: sampleLocation,
        locationManager: LocationManager(),
        weatherService: WeatherService(),
        showingAbout: .constant(false)
    )
}
