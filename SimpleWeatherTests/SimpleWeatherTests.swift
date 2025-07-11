//
//  SimpleWeatherTests.swift
//  SimpleWeatherTests
//
//  Created by Farley Caesar on 2025-05-26.
//

import Testing
import CoreLocation
import SwiftData
@testable import SimpleWeather

// MARK: - LocationManager Tests
@Suite("LocationManager Tests")
struct LocationManagerTests {
    
    @Test("LocationManager initialization")
    @MainActor
    func locationManagerInitialization() throws {
        let container = try ModelContainer(for: SavedLocation.self, CachedLocation.self, 
                                         configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let locationCache = LocationCache(modelContext: container.mainContext)
        let locationManager = LocationManager(locationCache: locationCache)
        
        #expect(locationManager.location == nil || locationManager.didUseCachedLocation == true)
        #expect(locationManager.isLoading == false)
        #expect(locationManager.locationError == nil)
    }
    
    @Test("Authorization status description")
    func authorizationStatusDescription() {
        #expect(CLAuthorizationStatus.notDetermined.description == "notDetermined")
        #expect(CLAuthorizationStatus.restricted.description == "restricted")
        #expect(CLAuthorizationStatus.denied.description == "denied")
        #expect(CLAuthorizationStatus.authorizedAlways.description == "authorizedAlways")
        #expect(CLAuthorizationStatus.authorizedWhenInUse.description == "authorizedWhenInUse")
    }
}

// MARK: - LocationCache Tests
@Suite("LocationCache Tests")
struct LocationCacheTests {
    
    @Test("Cached location data structure")
    func cachedLocationDataStructure() {
        let testLocation = CLLocation(latitude: 51.5074, longitude: -0.1278) // London
        let cachedLocation = CachedLocation(location: testLocation)
        
        #expect(cachedLocation.latitude == testLocation.coordinate.latitude)
        #expect(cachedLocation.longitude == testLocation.coordinate.longitude)
        #expect(cachedLocation.location.coordinate.latitude == testLocation.coordinate.latitude)
        #expect(cachedLocation.location.coordinate.longitude == testLocation.coordinate.longitude)
        #expect(cachedLocation.isStale == false) // Should be fresh
    }
    
    @Test("Cached location isStale property")
    func cachedLocationIsStale() {
        let testLocation = CLLocation(latitude: 48.8566, longitude: 2.3522) // Paris
        let cachedLocation = CachedLocation(location: testLocation)
        
        // Fresh cache should not be stale
        #expect(cachedLocation.isStale == false)
        
        // Test stale detection logic - create a location with old timestamp manually
        let oldTimestamp = Date().addingTimeInterval(-25 * 60 * 60) // 25 hours ago
        let mockOldCachedLocation = MockCachedLocation(timestamp: oldTimestamp)
        #expect(mockOldCachedLocation.isStale == true)
    }
    
    @Test("LocationCache SwiftData operations")
    @MainActor
    func locationCacheSwiftDataOperations() throws {
        let container = try ModelContainer(for: SavedLocation.self, CachedLocation.self, 
                                         configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let locationCache = LocationCache(modelContext: container.mainContext)
        
        let testLocation = CLLocation(latitude: 40.7128, longitude: -74.0060) // New York
        
        // Initially no cached location
        #expect(locationCache.getCachedLocation() == nil)
        
        // Cache a location
        locationCache.cacheLocation(testLocation)
        
        // Retrieve cached location
        let cachedLocation = locationCache.getCachedLocation()
        #expect(cachedLocation != nil)
        #expect(cachedLocation?.coordinate.latitude == testLocation.coordinate.latitude)
        #expect(cachedLocation?.coordinate.longitude == testLocation.coordinate.longitude)
        
        // Clear cache
        locationCache.clearCache()
        #expect(locationCache.getCachedLocation() == nil)
    }
}

// MARK: - LocationStorage Tests
@Suite("LocationStorage Tests")
struct LocationStorageTests {
    
    @Test("LocationStorage basic operations")
    @MainActor
    func locationStorageBasicOperations() throws {
        let container = try ModelContainer(for: SavedLocation.self, CachedLocation.self, 
                                         configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let locationStorage = LocationStorage(modelContext: container.mainContext)
        
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco
        let location = SavedLocation(name: "San Francisco", coordinate: coordinate, isCurrentLocation: false)
        
        // Initially no saved locations
        #expect(locationStorage.savedLocations.isEmpty)
        
        // Save a location
        locationStorage.saveLocation(location)
        #expect(locationStorage.savedLocations.count == 1)
        #expect(locationStorage.savedLocations.first?.name == "San Francisco")
        
        // Remove the location (need to get the actual saved location since saveLocation creates a new one)
        let savedLocation = locationStorage.savedLocations.first!
        locationStorage.removeLocation(savedLocation)
        #expect(locationStorage.savedLocations.isEmpty)
    }
    
    @Test("LocationStorage current location handling")
    @MainActor
    func locationStorageCurrentLocationHandling() throws {
        let container = try ModelContainer(for: SavedLocation.self, CachedLocation.self, 
                                         configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let locationStorage = LocationStorage(modelContext: container.mainContext)
        
        let coordinate = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278) // London
        let currentLocation = SavedLocation(name: "Current Location", coordinate: coordinate, isCurrentLocation: true)
        let savedLocation = SavedLocation(name: "London", coordinate: coordinate, isCurrentLocation: false)
        
        // Initially no current location
        #expect(locationStorage.currentLocation == nil)
        
        // Save a regular location (not current location)
        locationStorage.saveLocation(savedLocation)
        #expect(locationStorage.otherLocations.count == 1)
        #expect(locationStorage.otherLocations.first?.name == "London")
        
        // Update current location (stored in memory only)
        locationStorage.updateCurrentLocation(currentLocation)
        #expect(locationStorage.currentLocation?.name == "Current Location")
        #expect(locationStorage.currentLocation?.isCurrentLocation == true)
        
        // Current location should not be persisted, so otherLocations should still be 1
        #expect(locationStorage.otherLocations.count == 1)
        #expect(locationStorage.otherLocations.first?.name == "London")
        
        // Update to a new current location
        let newCoordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522) // Paris
        let newCurrentLocation = SavedLocation(name: "Paris", coordinate: newCoordinate, isCurrentLocation: true)
        locationStorage.updateCurrentLocation(newCurrentLocation)
        
        #expect(locationStorage.currentLocation?.name == "Paris")
        // otherLocations should still only have the London location
        #expect(locationStorage.otherLocations.count == 1)
        #expect(locationStorage.otherLocations.first?.name == "London")
    }
    
    @Test("LocationStorage prevents saving current locations to database")
    @MainActor
    func locationStoragePreventsSavingCurrentLocations() throws {
        let container = try ModelContainer(for: SavedLocation.self, CachedLocation.self, 
                                         configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let locationStorage = LocationStorage(modelContext: container.mainContext)
        
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // San Francisco
        let currentLocation = SavedLocation(name: "Current Location", coordinate: coordinate, isCurrentLocation: true)
        
        // Try to save a current location - it should be converted to a regular saved location
        locationStorage.saveLocation(currentLocation)
        
        // The location should be saved but marked as isCurrentLocation: false
        #expect(locationStorage.savedLocations.count == 1)
        #expect(locationStorage.savedLocations.first?.name == "Current Location")
        #expect(locationStorage.savedLocations.first?.isCurrentLocation == false)
        
        // Should still have no current location in memory
        #expect(locationStorage.currentLocation == nil)
    }
}

// MARK: - SavedLocation Tests
@Suite("SavedLocation Tests")
struct SavedLocationTests {
    
    @Test("SavedLocation creation")
    func savedLocationCreation() {
        let coordinate = CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437) // Los Angeles
        let location = SavedLocation(name: "Los Angeles", coordinate: coordinate, isCurrentLocation: false)
        
        #expect(location.name == "Los Angeles")
        #expect(location.latitude == coordinate.latitude)
        #expect(location.longitude == coordinate.longitude)
        #expect(location.isCurrentLocation == false)
        #expect(location.coordinate.latitude == coordinate.latitude)
        #expect(location.coordinate.longitude == coordinate.longitude)
    }
    
    @Test("SavedLocation current location flag")
    func savedLocationCurrentLocationFlag() {
        let coordinate = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503) // Tokyo
        let currentLocation = SavedLocation(name: "Current Location", coordinate: coordinate, isCurrentLocation: true)
        let savedLocation = SavedLocation(name: "Tokyo", coordinate: coordinate, isCurrentLocation: false)
        
        #expect(currentLocation.isCurrentLocation == true)
        #expect(savedLocation.isCurrentLocation == false)
    }
    
    @Test("SavedLocation equality")
    func savedLocationEquality() {
        let coordinate = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522) // Paris
        let location1 = SavedLocation(name: "Paris", coordinate: coordinate)
        let location2 = SavedLocation(name: "Paris", coordinate: coordinate)
        
        // Different instances should have different IDs and not be equal
        #expect(location1 != location2)
        #expect(location1.id != location2.id)
        
        // Same instance should be equal to itself
        #expect(location1 == location1)
    }
    
    @Test("SavedLocation SwiftData persistence")
    @MainActor
    func savedLocationSwiftDataPersistence() throws {
        let container = try ModelContainer(for: SavedLocation.self, CachedLocation.self, 
                                         configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        
        let coordinate = CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176) // Moscow
        let originalLocation = SavedLocation(name: "Moscow", coordinate: coordinate, isCurrentLocation: true)
        
        // Save to SwiftData
        context.insert(originalLocation)
        try context.save()
        
        // Fetch from SwiftData
        let descriptor = FetchDescriptor<SavedLocation>()
        let savedLocations = try context.fetch(descriptor)
        
        #expect(savedLocations.count == 1)
        let retrievedLocation = savedLocations.first!
        #expect(retrievedLocation.name == "Moscow")
        #expect(retrievedLocation.latitude == 55.7558)
        #expect(retrievedLocation.longitude == 37.6176)
        #expect(retrievedLocation.isCurrentLocation == true)
    }
}

// MARK: - WeatherService Tests
@Suite("WeatherService Tests")
struct WeatherServiceTests {
    
    @Test("WeatherService initialization")
    @MainActor
    func weatherServiceInitialization() {
        let weatherService = WeatherService()
        
        #expect(weatherService.currentWeather == nil)
        #expect(weatherService.dailyForecast == nil)
        #expect(weatherService.hourlyForecast == nil)
        #expect(weatherService.isLoadingCurrentWeather == false)
        #expect(weatherService.isLoadingForecast == false)
        #expect(weatherService.weatherError == nil)
    }
    
    @Test("LocationWeatherData structure")
    func locationWeatherDataStructure() {
        let currentWeather = createMockCurrentWeather()
        let dailyForecast = [createMockDailyForecast()]
        let hourlyForecast = [createMockHourlyForecast()]
        let timestamp = Date()
        
        let locationData = WeatherService.LocationWeatherData(
            currentWeather: currentWeather,
            dailyForecast: dailyForecast,
            hourlyForecast: hourlyForecast,
            lastUpdated: timestamp
        )
        
        #expect(locationData.currentWeather.temperature.value > 0)
        #expect(locationData.dailyForecast.count == 1)
        #expect(locationData.hourlyForecast.count == 1)
        #expect(locationData.lastUpdated == timestamp)
    }
    
    @Test("Cache validity check")
    @MainActor
    func cacheValidityCheck() {
        let weatherService = WeatherService()
        let location = SavedLocation(name: "Test City", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        
        // Initially no cached data
        let cachedData = weatherService.getCachedWeather(for: location)
        #expect(cachedData == nil)
    }
}

// MARK: - Data Model Tests
@Suite("Weather Data Models Tests")
struct WeatherDataModelTests {
    
    @Test("CurrentWeather model")
    func currentWeatherModel() {
        let currentWeather = createMockCurrentWeather()
        
        #expect(!currentWeather.id.uuidString.isEmpty)
        #expect(currentWeather.temperature.value > 0)
        #expect(currentWeather.conditionDescription.isEmpty == false)
        #expect(currentWeather.conditionSymbolName.isEmpty == false)
        #expect(currentWeather.humidityFraction >= 0 && currentWeather.humidityFraction <= 1)
        #expect(currentWeather.uvIndexValue >= 0)
    }
    
    @Test("DailyForecast model")
    func dailyForecastModel() {
        let forecast = createMockDailyForecast()
        
        #expect(!forecast.id.uuidString.isEmpty)
        #expect(forecast.highTemperature.value >= forecast.lowTemperature.value)
        #expect(forecast.conditionSymbolName.isEmpty == false)
        #expect(forecast.conditionDescription.isEmpty == false)
        #expect(forecast.precipitationChance >= 0 && forecast.precipitationChance <= 1)
    }
    
    @Test("HourlyForecast model")
    func hourlyForecastModel() {
        let forecast = createMockHourlyForecast()
        
        #expect(!forecast.id.uuidString.isEmpty)
        #expect(forecast.temperature.value != 0)
        #expect(forecast.conditionSymbolName.isEmpty == false)
        #expect(forecast.conditionDescription.isEmpty == false)
        #expect(forecast.precipitationChance >= 0 && forecast.precipitationChance <= 1)
    }
    
    @Test("Weather models Hashable conformance")
    func weatherModelsHashableConformance() {
        let currentWeather1 = createMockCurrentWeather()
        let currentWeather2 = createMockCurrentWeather()
        
        // Different instances should have different hashes due to different UUIDs
        #expect(currentWeather1.hashValue != currentWeather2.hashValue)
        
        let dailyForecast1 = createMockDailyForecast()
        let dailyForecast2 = createMockDailyForecast()
        
        #expect(dailyForecast1.hashValue != dailyForecast2.hashValue)
        
        let hourlyForecast1 = createMockHourlyForecast()
        let hourlyForecast2 = createMockHourlyForecast()
        
        #expect(hourlyForecast1.hashValue != hourlyForecast2.hashValue)
    }
}

// MARK: - Helper Classes for Testing
private struct MockCachedLocation {
    let timestamp: Date
    
    var isStale: Bool {
        // Same logic as CachedLocation
        let cacheExpiration: TimeInterval = 60 * 60 * 24 // 24 hours
        return abs(timestamp.timeIntervalSinceNow) > cacheExpiration
    }
}

// MARK: - Helper Functions
private func createMockCurrentWeather() -> CurrentWeather {
    CurrentWeather(
        date: Date(),
        temperature: Measurement(value: 22.0, unit: UnitTemperature.celsius),
        conditionDescription: "Partly Cloudy",
        conditionSymbolName: "cloud.sun",
        feelsLikeTemperature: Measurement(value: 24.0, unit: UnitTemperature.celsius),
        windSpeed: Measurement(value: 5.0, unit: UnitSpeed.kilometersPerHour),
        windDirection: Measurement(value: 180.0, unit: UnitAngle.degrees),
        humidityFraction: 0.65,
        uvIndexValue: 3,
        uvIndexCategory: "Moderate",
        precipitationIntensity: Measurement(value: 0.0, unit: UnitSpeed.metersPerSecond),
        precipitationChance: 0.2,
        precipitationChanceToday: 0.3,
        pressure: Measurement(value: 1013.25, unit: UnitPressure.hectopascals)
    )
}

private func createMockDailyForecast() -> DailyForecast {
    DailyForecast(
        date: Date(),
        highTemperature: Measurement(value: 25.0, unit: UnitTemperature.celsius),
        lowTemperature: Measurement(value: 15.0, unit: UnitTemperature.celsius),
        conditionSymbolName: "sun.max",
        conditionDescription: "Sunny",
        precipitationChance: 0.1,
        precipitationChanceToday: nil
    )
}

private func createMockHourlyForecast() -> HourlyForecast {
    HourlyForecast(
        date: Date(),
        temperature: Measurement(value: 20.0, unit: UnitTemperature.celsius),
        conditionSymbolName: "cloud",
        conditionDescription: "Cloudy",
        precipitationChance: 0.4
    )
}
