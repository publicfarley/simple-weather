import Foundation
import CoreLocation

@Observable
class GeocodingService {
    private let geocoder = CLGeocoder()
    private let timeoutInterval: TimeInterval = 10.0
    
    init() {}
    
    func searchLocations(for query: String) async throws -> [SavedLocation] {
        return try await withTimeout(timeoutInterval) {
            try await withCheckedThrowingContinuation { continuation in
                self.geocoder.geocodeAddressString(query) { placemarks, error in
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
    }
    
    func reverseGeocode(coordinate: CLLocationCoordinate2D) async throws -> String {
        return try await withTimeout(timeoutInterval) {
            try await withCheckedThrowingContinuation { continuation in
                let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                
                self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
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
    }
    
    func cancelAllRequests() {
        geocoder.cancelGeocode()
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
    
    private func withTimeout<T>(_ timeout: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw GeocodingError.timeout
            }
            
            guard let result = try await group.next() else {
                throw GeocodingError.timeout
            }
            
            group.cancelAll()
            return result
        }
    }
}

enum GeocodingError: LocalizedError {
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Location request timed out. Please check your internet connection and try again."
        }
    }
}
