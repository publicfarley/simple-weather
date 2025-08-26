import SwiftUI

struct LocationListView: View {
    @Environment(LocationStorage.self) private var locationStorage
    @Environment(LocationManager.self) private var locationManager
    @Environment(GeocodingService.self) private var geocodingService
    @State private var showingAddLocation = false
    @State private var isLoadingCurrentLocation = false
    @State private var locationError: String? = nil
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
                            
                            if isLoadingCurrentLocation {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if selectedLocation?.isCurrentLocation == true {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .font(.headline)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isLoadingCurrentLocation)
                } header: {
                    Text("Current Location")
                } footer: {
                    if let locationError = locationError {
                        Text(locationError)
                            .foregroundColor(.red)
                    } else {
                        Text("This is the recommended option for most accurate weather information.")
                    }
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
        await MainActor.run {
            isLoadingCurrentLocation = true
            locationError = nil
        }
        
        defer {
            Task { @MainActor in
                isLoadingCurrentLocation = false
            }
        }
        
        do {
            // Request fresh current location
            locationManager.requestLocation()
            
            // Wait for location update with timeout
            let maxWaitTime = 5.0
            let checkInterval = 0.1
            var waitTime = 0.0
            
            while waitTime < maxWaitTime && locationManager.location == nil && locationManager.isLoading {
                try await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                waitTime += checkInterval
                
                // Check for cancellation
                try Task.checkCancellation()
            }
            
            guard let location = locationManager.location else {
                // Fallback to cached location if available
                if let currentLocation = locationStorage.currentLocation {
                    await MainActor.run {
                        selectedLocation = currentLocation
                    }
                    dismiss()
                    return
                } else {
                    throw LocationError.unavailable
                }
            }
            
            // Reverse geocode with timeout handling
            let locationName = try await geocodingService.reverseGeocode(coordinate: location.coordinate)
            let currentLocation = SavedLocation(
                name: locationName,
                coordinate: location.coordinate,
                isCurrentLocation: true
            )
            
            await MainActor.run {
                locationStorage.updateCurrentLocation(currentLocation)
                selectedLocation = currentLocation
            }
            dismiss()
            
        } catch is CancellationError {
            // Task was cancelled, don't show error
            return
        } catch {
            await MainActor.run {
                locationError = error.localizedDescription
            }
            
            // Try to use cached location as fallback
            if let currentLocation = locationStorage.currentLocation {
                await MainActor.run {
                    selectedLocation = currentLocation
                }
                dismiss()
            }
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

enum LocationError: LocalizedError {
    case unavailable
    
    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Unable to access current location. Please check location permissions or try again."
        }
    }
}
