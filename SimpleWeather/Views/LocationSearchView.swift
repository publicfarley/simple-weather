import SwiftUI

struct LocationSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GeocodingService.self) private var geocodingService
    @Environment(LocationStorage.self) private var locationStorage
    
    @State private var searchText = ""
    @State private var searchResults: [SavedLocation] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText, onSearchButtonClicked: performSearch)
                
                if isSearching {
                    ProgressView("Searching...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    Text("No locations found")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(searchResults) { location in
                        LocationSearchResultRow(location: location) {
                            addLocation(location)
                        }
                    }
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Add Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isSearching = true
        errorMessage = nil
        
        Task {
            do {
                let results = try await geocodingService.searchLocations(for: searchText)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to search locations: \(error.localizedDescription)"
                    isSearching = false
                }
            }
        }
    }
    
    private func addLocation(_ location: SavedLocation) {
        locationStorage.saveLocation(location)
        dismiss()
    }
}

struct SearchBar: View {
    @Binding var text: String
    var onSearchButtonClicked: () -> Void
    
    var body: some View {
        HStack {
            TextField("Search for a city", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    onSearchButtonClicked()
                }
            
            Button("Search", action: onSearchButtonClicked)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}

struct LocationSearchResultRow: View {
    let location: SavedLocation
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(location.name)
                    .font(.headline)
                Text("\(location.latitude, specifier: "%.4f"), \(location.longitude, specifier: "%.4f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Add") {
                onAdd()
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LocationSearchView()
}