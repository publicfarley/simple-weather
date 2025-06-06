import Foundation

class LocationStorage: ObservableObject {
    static let shared = LocationStorage()
    
    @Published var savedLocations: [SavedLocation] = []
    
    private let userDefaults = UserDefaults.standard
    private let savedLocationsKey = "SavedLocations"
    
    private init() {
        loadSavedLocations()
    }
    
    func saveLocation(_ location: SavedLocation) {
        if !savedLocations.contains(location) {
            savedLocations.append(location)
            persistLocations()
        }
    }
    
    func removeLocation(_ location: SavedLocation) {
        savedLocations.removeAll { $0.id == location.id }
        persistLocations()
    }
    
    func removeLocation(at index: Int) {
        guard index < savedLocations.count else { return }
        savedLocations.remove(at: index)
        persistLocations()
    }
    
    func updateCurrentLocation(_ location: SavedLocation) {
        savedLocations.removeAll { $0.isCurrentLocation }
        savedLocations.insert(location, at: 0)
        persistLocations()
    }
    
    var currentLocation: SavedLocation? {
        savedLocations.first { $0.isCurrentLocation }
    }
    
    var otherLocations: [SavedLocation] {
        savedLocations.filter { !$0.isCurrentLocation }
    }
    
    private func persistLocations() {
        if let encoded = try? JSONEncoder().encode(savedLocations) {
            userDefaults.set(encoded, forKey: savedLocationsKey)
        }
    }
    
    private func loadSavedLocations() {
        if let data = userDefaults.data(forKey: savedLocationsKey),
           let locations = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            savedLocations = locations
        }
    }
}