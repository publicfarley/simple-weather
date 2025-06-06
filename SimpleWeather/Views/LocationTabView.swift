import SwiftUI
import CoreLocation

struct LocationTabView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherService = WeatherService()
    @StateObject private var locationStorage = LocationStorage.shared
    @StateObject private var geocodingService = GeocodingService.shared
    
    @State private var selectedLocation: SavedLocation?
    @State private var showingLocationList = false
    @State private var isInitialized = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let selectedLocation = selectedLocation {
                    WeatherContentView(
                        location: selectedLocation,
                        locationManager: locationManager,
                        weatherService: weatherService
                    )
                } else {
                    EmptyStateView()
                }
            }
            .navigationTitle(selectedLocation?.name ?? "SimpleWeather")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
    }
    
    private func initializeDefaultLocation() async {
        // Check if we have a current location saved
        if let currentLocation = locationStorage.currentLocation {
            selectedLocation = currentLocation
            return
        }
        
        // Request location permission and get current location
        locationManager.requestLocationAccess()
        
        // Wait a moment for location to be determined
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        if let location = locationManager.location {
            await updateCurrentLocationIfNeeded(location)
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
            
            // Update selected location if it's the current location or if no location is selected
            if selectedLocation?.isCurrentLocation == true || selectedLocation == nil {
                selectedLocation = currentLocation
            }
        } catch {
            print("Failed to reverse geocode current location: \(error)")
            // Create a fallback current location
            let fallbackLocation = SavedLocation(
                name: "Current Location",
                coordinate: location.coordinate,
                isCurrentLocation: true
            )
            locationStorage.updateCurrentLocation(fallbackLocation)
            
            if selectedLocation?.isCurrentLocation == true || selectedLocation == nil {
                selectedLocation = fallbackLocation
            }
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