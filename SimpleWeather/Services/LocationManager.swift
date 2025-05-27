import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    @Published var location: CLLocation? = nil
    @Published var isLoading: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var locationError: Error? = nil

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        print("[LocationManager] Initialized. Authorization status: \(authorizationStatus.description)")
    }

    func requestLocationAccess() {
        isLoading = true // Indicate loading when access request starts
        print("[LocationManager] requestLocationAccess called.")
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            // If already authorized, directly request location
            print("[LocationManager] Already authorized. Requesting location.")
            locationManager.requestLocation() // This is for a one-time location update
        } else {
            // Denied or restricted, isLoading should be false as we can't proceed.
            isLoading = false
            print("[LocationManager] Location access denied or restricted. Status: \(authorizationStatus.description)")
            // Optionally, set an error or update UI to guide user to settings
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
            self.location = newLocation
            self.locationError = nil // Clear any previous error
            print("[LocationManager] Did update locations: \(newLocation.coordinate)")
        } else {
            print("[LocationManager] Did update locations: Received empty locations array.")
        }
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
                // Optionally, set an error to inform the user they need to enable permissions in settings
                // self.locationError = LocationError.permissionDenied // Define a custom error type if needed
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
