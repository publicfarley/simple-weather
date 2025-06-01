import CoreLocation
import Foundation

struct CachedLocation: Codable {
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    let timestamp: Date
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = Date()
    }
    
    var isStale: Bool {
        // Consider cache valid for 24 hours
        let cacheExpiration: TimeInterval = 60 * 60 * 24 // 24 hours
        return abs(timestamp.timeIntervalSinceNow) > cacheExpiration
    }
}

class LocationCache {
    static let shared = LocationCache()
    private let cacheKey = "cachedLocation"
    
    private init() {}
    
    func cacheLocation(_ location: CLLocation) {
        let cachedLocation = CachedLocation(location: location)
        if let encoded = try? JSONEncoder().encode(cachedLocation) {
            UserDefaults.standard.set(encoded, forKey: cacheKey)
        }
    }
    
    func getCachedLocation() -> CLLocation? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cachedLocation = try? JSONDecoder().decode(CachedLocation.self, from: data),
              !cachedLocation.isStale else {
            return nil
        }
        return cachedLocation.location
    }
    
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
    }
}
