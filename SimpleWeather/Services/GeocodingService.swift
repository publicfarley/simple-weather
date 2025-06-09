import Foundation
import CoreLocation

@Observable
class GeocodingService {
    private let geocoder = CLGeocoder()
    
    init() {}
    
    func searchLocations(for query: String) async throws -> [SavedLocation] {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.geocodeAddressString(query) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemarks = placemarks else {
                    continuation.resume(returning: [])
                    return
                }
                
                let locations = placemarks.compactMap { placemark -> SavedLocation? in
                    guard let coordinate = placemark.location?.coordinate else { return nil }
                    
                    let name = self.formatLocationName(from: placemark)
                    return SavedLocation(name: name, coordinate: coordinate)
                }
                
                continuation.resume(returning: locations)
            }
        }
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    continuation.resume(returning: "Unknown Location")
                    return
                }
                
                let name = self.formatLocationName(from: placemark)
                continuation.resume(returning: name)
            }
        }
    }
    
    private func formatLocationName(from placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.isEmpty ? "Unknown Location" : components.joined(separator: ", ")
    }
}