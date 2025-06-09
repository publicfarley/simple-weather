import SwiftUI

struct LocationListView: View {
    @Environment(LocationStorage.self) private var locationStorage
    @Environment(LocationManager.self) private var locationManager
    @Environment(GeocodingService.self) private var geocodingService
    @State private var showingAddLocation = false
    @Binding var selectedLocation: SavedLocation?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: {
                        Task {
                            await useCurrentLocation()
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 28, height: 28)
                                .background(Color.blue)
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Use Current Location")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Always shows weather for your current location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedLocation?.isCurrentLocation == true {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.headline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text("Current Location")
                } footer: {
                    Text("This is the recommended option for most accurate weather information.")
                }
                
                if let currentLocation = locationStorage.currentLocation {
                    Section("Detected Location") {
                        LocationRow(location: currentLocation, isSelected: false) {
                            // This shows the detected location but doesn't allow selection
                            // Users should use the "Use Current Location" button above
                        }
                        .disabled(true)
                        .opacity(0.7)
                    }
                }
                
                if !locationStorage.otherLocations.isEmpty {
                    Section("Saved Locations") {
                        ForEach(locationStorage.otherLocations) { location in
                            LocationRow(location: location, isSelected: selectedLocation?.id == location.id) {
                                selectedLocation = location
                                dismiss()
                            }
                        }
                        .onDelete(perform: deleteLocations)
                    }
                }
            }
            .navigationTitle("Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddLocation = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddLocation) {
            LocationSearchView()
        }
    }
    
    private func useCurrentLocation() async {
        // Request fresh current location
        locationManager.requestLocation()
        
        // Wait briefly for location update
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        if let location = locationManager.location {
            do {
                let locationName = try await geocodingService.reverseGeocode(coordinate: location.coordinate)
                let currentLocation = SavedLocation(
                    name: locationName,
                    coordinate: location.coordinate,
                    isCurrentLocation: true
                )
                
                locationStorage.updateCurrentLocation(currentLocation)
                selectedLocation = currentLocation
                dismiss()
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
                dismiss()
            }
        } else if let currentLocation = locationStorage.currentLocation {
            // Use cached current location if GPS fails
            selectedLocation = currentLocation
            dismiss()
        }
    }
    
    private func deleteLocations(offsets: IndexSet) {
        for index in offsets {
            let location = locationStorage.otherLocations[index]
            locationStorage.removeLocation(location)
        }
    }
}

struct LocationRow: View {
    let location: SavedLocation
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(location.name)
                    .font(.headline)
                
                if location.isCurrentLocation {
                    Text("Current Location")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
                    .font(.headline)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    @Previewable @State var selectedLocation: SavedLocation? = nil
    return LocationListView(selectedLocation: $selectedLocation)
}
