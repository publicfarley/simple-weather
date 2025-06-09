import Foundation
import SwiftData

@Observable
class LocationStorage {
    private let modelContext: ModelContext
    private var _savedLocations: [SavedLocation] = []
    private var _currentLocation: SavedLocation? = nil
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        cleanupCurrentLocations()
        refreshLocations()
    }
    
    var savedLocations: [SavedLocation] {
        return _savedLocations
    }
    
    private func refreshLocations() {
        do {
            let descriptor = FetchDescriptor<SavedLocation>(
                predicate: #Predicate<SavedLocation> { !$0.isCurrentLocation }
            )
            _savedLocations = try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching saved locations: \(error)")
            _savedLocations = []
        }
    }
    
    func saveLocation(_ location: SavedLocation) {
        // Ensure this is not a current location being saved
        let locationToSave = SavedLocation(
            name: location.name,
            coordinate: location.coordinate,
            isCurrentLocation: false
        )
        
        let existingLocations = savedLocations
        if !existingLocations.contains(where: { 
            $0.coordinate.latitude == locationToSave.coordinate.latitude && 
            $0.coordinate.longitude == locationToSave.coordinate.longitude 
        }) {
            modelContext.insert(locationToSave)
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
        // Store current location in memory only, don't persist to database
        _currentLocation = location
    }
    
    var currentLocation: SavedLocation? {
        return _currentLocation
    }
    
    var otherLocations: [SavedLocation] {
        return savedLocations // All saved locations are "other" locations since current location is not persisted
    }
    
    private func cleanupCurrentLocations() {
        // Remove any previously persisted current locations from the database
        do {
            let descriptor = FetchDescriptor<SavedLocation>(
                predicate: #Predicate<SavedLocation> { $0.isCurrentLocation }
            )
            let currentLocations = try modelContext.fetch(descriptor)
            for location in currentLocations {
                modelContext.delete(location)
            }
            try modelContext.save()
        } catch {
            print("Error cleaning up current locations: \(error)")
        }
    }
}