//
//  SimpleWeatherTests.swift
//  SimpleWeatherTests
//
//  Created by Farley Caesar on 2025-05-26.
//

import Testing
import CoreLocation
@testable import SimpleWeather

// MARK: - LocationManager Tests
@Suite("LocationManager Tests")
struct LocationManagerTests {
    
    @Test("LocationManager initialization")
    func locationManagerInitialization() {
        let locationManager = LocationManager()
        
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
    
    @Test("SavedLocation Codable conformance")
    func savedLocationCodableConformance() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 55.7558, longitude: 37.6176) // Moscow
        let originalLocation = SavedLocation(name: "Moscow", coordinate: coordinate, isCurrentLocation: true)
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalLocation)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedLocation = try decoder.decode(SavedLocation.self, from: data)
        
        #expect(decodedLocation.name == originalLocation.name)
        #expect(decodedLocation.latitude == originalLocation.latitude)
        #expect(decodedLocation.longitude == originalLocation.longitude)
        #expect(decodedLocation.isCurrentLocation == originalLocation.isCurrentLocation)
        // Note: ID is not coded, so it will be different
        #expect(decodedLocation.id != originalLocation.id)
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
