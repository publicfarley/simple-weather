import CoreLocation
import Foundation
import SwiftData

class LocationCache {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func cacheLocation(_ location: CLLocation) {
        clearCache()
        let cachedLocation = CachedLocation(location: location)
        modelContext.insert(cachedLocation)
        try? modelContext.save()
    }
    
    func getCachedLocation() -> CLLocation? {
        do {
            let descriptor = FetchDescriptor<CachedLocation>()
            let cachedLocations = try modelContext.fetch(descriptor)
            
            guard let cachedLocation = cachedLocations.first,
                  !cachedLocation.isStale else {
                clearCache()
                return nil
            }
            
            return cachedLocation.location
        } catch {
            print("Error fetching cached location: \(error)")
            return nil
        }
    }
    
    func clearCache() {
        do {
            let descriptor = FetchDescriptor<CachedLocation>()
            let cachedLocations = try modelContext.fetch(descriptor)
            for cachedLocation in cachedLocations {
                modelContext.delete(cachedLocation)
            }
            try modelContext.save()
        } catch {
            print("Error clearing location cache: \(error)")
        }
    }
}
