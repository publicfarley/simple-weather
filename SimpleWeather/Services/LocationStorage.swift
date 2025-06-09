import Foundation
import SwiftData

@Observable
class LocationStorage {
    private let modelContext: ModelContext
    private var _savedLocations: [SavedLocation] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refreshLocations()
    }
    
    var savedLocations: [SavedLocation] {
        return _savedLocations
    }
    
    private func refreshLocations() {
        do {
            let descriptor = FetchDescriptor<SavedLocation>()
            let allLocations = try modelContext.fetch(descriptor)
            _savedLocations = allLocations.sorted { $0.isCurrentLocation && !$1.isCurrentLocation }
        } catch {
            print("Error fetching saved locations: \(error)")
            _savedLocations = []
        }
    }
    
    func saveLocation(_ location: SavedLocation) {
        let existingLocations = savedLocations
        if !existingLocations.contains(where: { $0.id == location.id }) {
            modelContext.insert(location)
            try? modelContext.save()
            refreshLocations()
        }
    }
    
    func removeLocation(_ location: SavedLocation) {
        modelContext.delete(location)
        try? modelContext.save()
        refreshLocations()
    }
    
    func removeLocation(at index: Int) {
        let locations = savedLocations
        guard index < locations.count else { return }
        let location = locations[index]
        modelContext.delete(location)
        try? modelContext.save()
        refreshLocations()
    }
    
    func updateCurrentLocation(_ location: SavedLocation) {
        let currentLocations = savedLocations.filter { $0.isCurrentLocation }
        for currentLocation in currentLocations {
            currentLocation.isCurrentLocation = false
        }
        
        location.isCurrentLocation = true
        modelContext.insert(location)
        try? modelContext.save()
        refreshLocations()
    }
    
    var currentLocation: SavedLocation? {
        savedLocations.first { $0.isCurrentLocation }
    }
    
    var otherLocations: [SavedLocation] {
        savedLocations.filter { !$0.isCurrentLocation }
    }
}