import Foundation
import SwiftData

@Observable
class LocationStorage {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    var savedLocations: [SavedLocation] {
        do {
            let descriptor = FetchDescriptor<SavedLocation>()
            let allLocations = try modelContext.fetch(descriptor)
            return allLocations.sorted { $0.isCurrentLocation && !$1.isCurrentLocation }
        } catch {
            print("Error fetching saved locations: \(error)")
            return []
        }
    }
    
    func saveLocation(_ location: SavedLocation) {
        let existingLocations = savedLocations
        if !existingLocations.contains(where: { $0.id == location.id }) {
            modelContext.insert(location)
            try? modelContext.save()
        }
    }
    
    func removeLocation(_ location: SavedLocation) {
        modelContext.delete(location)
        try? modelContext.save()
    }
    
    func removeLocation(at index: Int) {
        let locations = savedLocations
        guard index < locations.count else { return }
        let location = locations[index]
        modelContext.delete(location)
        try? modelContext.save()
    }
    
    func updateCurrentLocation(_ location: SavedLocation) {
        let currentLocations = savedLocations.filter { $0.isCurrentLocation }
        for currentLocation in currentLocations {
            currentLocation.isCurrentLocation = false
        }
        
        location.isCurrentLocation = true
        modelContext.insert(location)
        try? modelContext.save()
    }
    
    var currentLocation: SavedLocation? {
        savedLocations.first { $0.isCurrentLocation }
    }
    
    var otherLocations: [SavedLocation] {
        savedLocations.filter { !$0.isCurrentLocation }
    }
}