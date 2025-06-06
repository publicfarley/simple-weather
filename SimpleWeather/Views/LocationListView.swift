import SwiftUI

struct LocationListView: View {
    @StateObject private var locationStorage = LocationStorage.shared
    @State private var showingAddLocation = false
    @Binding var selectedLocation: SavedLocation?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if let currentLocation = locationStorage.currentLocation {
                    Section("Current Location") {
                        LocationRow(location: currentLocation, isSelected: selectedLocation?.id == currentLocation.id) {
                            selectedLocation = currentLocation
                            dismiss()
                        }
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
                
                if locationStorage.savedLocations.isEmpty {
                    Section {
                        Text("No saved locations")
                            .foregroundColor(.secondary)
                            .italic()
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
