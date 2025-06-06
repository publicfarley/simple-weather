import Foundation
import CoreLocation

struct SavedLocation: Codable, Identifiable, Equatable {
    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    let isCurrentLocation: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, latitude, longitude, isCurrentLocation
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    init(name: String, coordinate: CLLocationCoordinate2D, isCurrentLocation: Bool = false) {
        self.name = name
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.isCurrentLocation = isCurrentLocation
    }
    
    static func == (lhs: SavedLocation, rhs: SavedLocation) -> Bool {
        lhs.id == rhs.id
    }
}