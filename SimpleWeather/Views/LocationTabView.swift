import SwiftUI
import CoreLocation

struct LocationTabView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(LocationStorage.self) private var locationStorage
    @Environment(GeocodingService.self) private var geocodingService
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var weatherService = WeatherService()
    
    @State private var selectedLocation: SavedLocation?
    @State private var showingLocationList = false
    @State private var isInitialized = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let selectedLocation = selectedLocation {
                    WeatherContentView(
                        location: selectedLocation,
                        locationManager: locationManager,
                        weatherService: weatherService,
                        showingAbout: $showingAbout
                    )
                } else {
                    EmptyStateView()
                }
            }
            .navigationTitle(selectedLocation?.name.components(separatedBy: ",").first ?? selectedLocation?.name ?? "SimpleWeather")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !showingAbout {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { showingLocationList = true }) {
                            Image(systemName: "location.circle")
                                .imageScale(.large)
                                .accessibilityLabel("Locations")
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showingLocationList = true }) {
                            Image(systemName: "plus.circle")
                                .imageScale(.large)
                                .accessibilityLabel("Add Location")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingLocationList) {
            LocationListView(selectedLocation: $selectedLocation)
        }
        .task {
            if !isInitialized {
                await initializeDefaultLocation()
                isInitialized = true
            }
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let newLocation = newLocation, selectedLocation?.isCurrentLocation == true {
                Task {
                    await updateCurrentLocationIfNeeded(newLocation)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active && isInitialized {
                Task {
                    await ensureCurrentLocationIsDefault()
                }
            }
        }
    }
    
    private func initializeDefaultLocation() async {
        // Always try to get current location first from GPS
        if let location = locationManager.location {
            await updateCurrentLocationIfNeeded(location)
            return
        }
        
        // Request fresh location permission and get current location
        locationManager.requestLocationAccess()
        
        // Wait for location to be determined, but be more responsive
        var waitTime = 0.0
        let maxWaitTime = 5.0 // Maximum 5 seconds
        let checkInterval = 0.1 // Check every 100ms
        
        while waitTime < maxWaitTime && locationManager.location == nil && locationManager.isLoading {
            try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
            waitTime += checkInterval
        }
        
        if let location = locationManager.location {
            await updateCurrentLocationIfNeeded(location)
        } else {
            // Only fallback to saved current location if GPS fails
            if let currentLocation = locationStorage.currentLocation {
                selectedLocation = currentLocation
            }
        }
    }
    
    private func ensureCurrentLocationIsDefault() async {
        // Always refresh to current location when app becomes active
        locationManager.requestLocation()
        
        // Wait briefly for location update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if let location = locationManager.location {
            await updateCurrentLocationIfNeeded(location)
            // Always set current location as selected when app becomes active
            if let currentLocation = locationStorage.currentLocation {
                selectedLocation = currentLocation
            }
        }
    }
    
    private func updateCurrentLocationIfNeeded(_ location: CLLocation) async {
        do {
            let locationName = try await geocodingService.reverseGeocode(coordinate: location.coordinate)
            let currentLocation = SavedLocation(
                name: locationName,
                coordinate: location.coordinate,
                isCurrentLocation: true
            )
            
            locationStorage.updateCurrentLocation(currentLocation)
            
            // Always update selected location to current location
            selectedLocation = currentLocation
        } catch {
            print("Failed to reverse geocode current location: \(error)")
            // Create a fallback current location
            let fallbackLocation = SavedLocation(
                name: "Current Location",
                coordinate: location.coordinate,
                isCurrentLocation: true
            )
            locationStorage.updateCurrentLocation(fallbackLocation)
            
            selectedLocation = fallbackLocation
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "location.slash")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Location Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the location button to add or select a location for weather information.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    LocationTabView()
}