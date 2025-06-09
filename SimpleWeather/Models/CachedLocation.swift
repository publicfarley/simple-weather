import CoreLocation
import Foundation
import SwiftData

@Model
final class CachedLocation {
    var latitude: CLLocationDegrees
    var longitude: CLLocationDegrees
    var timestamp: Date
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.timestamp = Date()
    }
    
    var isStale: Bool {
        let cacheExpiration: TimeInterval = 60 * 60 * 24 // 24 hours
        return abs(timestamp.timeIntervalSinceNow) > cacheExpiration
    }
}