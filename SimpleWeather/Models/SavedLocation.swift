import Foundation
import CoreLocation
import SwiftData

@Model
final class SavedLocation {
    @Attribute(.unique) var id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var isCurrentLocation: Bool
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(name: String, coordinate: CLLocationCoordinate2D, isCurrentLocation: Bool = false) {
        self.id = UUID()
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.isCurrentLocation = isCurrentLocation
    }
}