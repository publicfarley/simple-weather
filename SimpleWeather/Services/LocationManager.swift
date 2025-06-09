import Foundation
import CoreLocation
import Combine

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let locationCache: LocationCache
    var didUseCachedLocation = false

    var location: CLLocation? = nil
    var isLoading: Bool = false
    var authorizationStatus: CLAuthorizationStatus
    var locationError: Error? = nil

    init(locationCache: LocationCache) {
        self.locationCache = locationCache
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        print("[LocationManager] Initialized. Authorization status: \(authorizationStatus.description)")
        
        // Try to load cached location first
        if let cachedLocation = locationCache.getCachedLocation() {
            self.location = cachedLocation
            self.didUseCachedLocation = true
            print("[LocationManager] Using cached location: \(cachedLocation.coordinate)")
        }
    }

    func requestLocationAccess() {
        isLoading = true // Indicate loading when access request starts
        print("[LocationManager] requestLocationAccess called.")
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // If already authorized, directly request location
            print("[LocationManager] Already authorized. Requesting location.")
            locationManager.requestLocation()
        } else {
            // Denied or restricted, isLoading should be false as we can't proceed.
            isLoading = false
            print("[LocationManager] Location access denied or restricted. Status: \(authorizationStatus.description)")
        }
    }

    func requestLocation() {
        isLoading = true
        locationManager.requestLocation()
    }

    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        isLoading = false
        if let newLocation = locations.last {
            // If we used a cached location and the new location is significantly different, update
            if didUseCachedLocation {
                if let oldLocation = self.location,
                   newLocation.distance(from: oldLocation) > 1000 { // 1km threshold
                    updateLocation(newLocation)
                }
            } else {
                updateLocation(newLocation)
            }
        } else {
            print("[LocationManager] Did update locations: Received empty locations array.")
        }
    }
    
    private func updateLocation(_ newLocation: CLLocation) {
        self.location = newLocation
        self.locationError = nil
        self.didUseCachedLocation = false
        locationCache.cacheLocation(newLocation)
        print("[LocationManager] Updated location: \(newLocation.coordinate)")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        print("[LocationManager] Did fail with error: \(error.localizedDescription)")
        locationError = error
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            print("[LocationManager] Did change authorization status: \(self.authorizationStatus.description)")
            switch self.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                print("[LocationManager] Authorized. Requesting location.")
                self.locationManager.requestLocation()
                self.isLoading = true // Start loading when authorized and requesting location
            case .denied, .restricted:
                print("[LocationManager] Denied or restricted. Clearing location and stopping loading.")
                self.location = nil
                self.isLoading = false
            case .notDetermined:
                print("[LocationManager] Authorization status changed to notDetermined.")
                self.isLoading = false // Not loading yet, waiting for user prompt response
            @unknown default:
                print("[LocationManager] Unknown authorization status.")
                self.isLoading = false
                self.location = nil
            }
        }
    }
}

// Helper to make CLAuthorizationStatus more readable in prints
extension CLAuthorizationStatus {
    var description: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorizedWhenInUse: return "authorizedWhenInUse"
        @unknown default: return "unknown"
        }
    }
}
