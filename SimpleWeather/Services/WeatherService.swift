import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    private let weatherService = WeatherKit.WeatherService.shared

    @Published var currentWeather: CurrentWeather? = nil
    @Published var dailyForecast: [DailyForecast]? = nil
    @Published var hourlyForecast: [HourlyForecast]? = nil
    @Published var isLoadingCurrentWeather: Bool = false
    @Published var isLoadingForecast: Bool = false
    @Published var weatherError: Error? = nil
    
    // Cache for location-specific weather data
    private var locationWeatherCache: [String: LocationWeatherData] = [:]
    
    struct LocationWeatherData {
        let currentWeather: CurrentWeather
        let dailyForecast: [DailyForecast]
        let hourlyForecast: [HourlyForecast]
        let lastUpdated: Date
    }

    init() {
        // Initialization code if needed
    }

    // Method to fetch weather for a SavedLocation
    func fetchWeather(for savedLocation: SavedLocation) async {
        let location = CLLocation(latitude: savedLocation.latitude, longitude: savedLocation.longitude)
        await fetchWeather(for: location)
    }
    
    // Method to get cached weather data for a location
    func getCachedWeather(for savedLocation: SavedLocation) -> LocationWeatherData? {
        let key = locationCacheKey(for: savedLocation)
        guard let cachedData = locationWeatherCache[key] else { return nil }
        
        // Check if cache is still valid (within 30 minutes)
        let cacheValidityDuration: TimeInterval = 30 * 60 // 30 minutes
        if Date().timeIntervalSince(cachedData.lastUpdated) > cacheValidityDuration {
            locationWeatherCache.removeValue(forKey: key)
            return nil
        }
        
        return cachedData
    }
    
    // Method to fetch weather for multiple locations concurrently
    func fetchWeatherForMultipleLocations(_ locations: [SavedLocation]) async -> [String: LocationWeatherData] {
        await withTaskGroup(of: (String, LocationWeatherData?).self) { group in
            var results: [String: LocationWeatherData] = [:]
            
            for location in locations {
                group.addTask {
                    let key = self.locationCacheKey(for: location)
                    do {
                        let weatherData = try await self.fetchWeatherData(for: location)
                        return (key, weatherData)
                    } catch {
                        print("[WeatherService] Failed to fetch weather for \(location.name): \(error)")
                        return (key, nil)
                    }
                }
            }
            
            for await (key, weatherData) in group {
                if let data = weatherData {
                    results[key] = data
                    self.locationWeatherCache[key] = data
                }
            }
            
            return results
        }
    }
    
    nonisolated private func locationCacheKey(for location: SavedLocation) -> String {
        return "\(location.latitude),\(location.longitude)"
    }
    
    private func fetchWeatherData(for savedLocation: SavedLocation) async throws -> LocationWeatherData {
        let location = CLLocation(latitude: savedLocation.latitude, longitude: savedLocation.longitude)
        
        async let current = getCurrentWeather(for: location)
        async let forecast = getSevenDayForecast(for: location)
        async let hourly = getHourlyForecast(for: location)
        
        let currentWeather = try await current
        let dailyForecast = try await forecast
        let hourlyForecast = try await hourly
        
        return LocationWeatherData(
            currentWeather: currentWeather,
            dailyForecast: dailyForecast,
            hourlyForecast: hourlyForecast,
            lastUpdated: Date()
        )
    }

    // Main method for ContentView to call
    func fetchWeather(for location: CLLocation) async {
        print("[WeatherService] fetchWeather called for location: \(location.coordinate)")
        isLoadingCurrentWeather = true
        isLoadingForecast = true
        weatherError = nil // Clear previous errors
        currentWeather = nil // Clear previous data
        dailyForecast = nil // Clear previous data
        hourlyForecast = nil // Clear previous data
        defer {
            isLoadingCurrentWeather = false
            isLoadingForecast = false
        }

        do {
            async let current = getCurrentWeather(for: location)
            async let forecast = getSevenDayForecast(for: location)
            async let hourly = getHourlyForecast(for: location)
            
            self.currentWeather = try await current
            self.dailyForecast = try await forecast
            self.hourlyForecast = try await hourly
            print("[WeatherService] fetchWeather: Successfully fetched current weather, daily forecast, and hourly forecast.")
        } catch {
            self.weatherError = error
            print("[WeatherService] fetchWeather: Failed to fetch weather. Error: \(error.localizedDescription)")
            // currentWeather and dailyForecast remain nil due to clearing above
        }
    }

    // In WeatherService.swift
    private func getCurrentWeather(for location: CLLocation) async throws -> CurrentWeather {
        // isLoadingCurrentWeather and weatherError are handled by the public fetchWeather method
        let weatherKitCurrentWeather = try await weatherService.weather(for: location, including: .current)
        
        // Get the daily forecast to ensure consistent precipitation data
        let dailyForecast = try await weatherService.weather(for: location, including: .daily)
        
        // Get today's forecast
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayForecast = dailyForecast.forecast.first { dayWeather in
            calendar.isDate(dayWeather.date, inSameDayAs: today)
        }
        
        // Get hourly forecast to calculate precipitation chance for rest of today
        let hourlyForecast = try await weatherService.weather(for: location, including: .hourly)
        let precipitationChanceToday = calculatePrecipitationChanceForRestOfToday(hourlyForecast: hourlyForecast.forecast)
        
        let customCurrentWeather = CurrentWeather(
            date: weatherKitCurrentWeather.date,
            temperature: weatherKitCurrentWeather.temperature,
            conditionDescription: weatherKitCurrentWeather.condition.description,
            conditionSymbolName: filledSymbolName(for: weatherKitCurrentWeather.symbolName),
            feelsLikeTemperature: weatherKitCurrentWeather.apparentTemperature,
            windSpeed: weatherKitCurrentWeather.wind.speed,
            windDirection: weatherKitCurrentWeather.wind.direction,
            humidityFraction: weatherKitCurrentWeather.humidity,
            uvIndexValue: weatherKitCurrentWeather.uvIndex.value,
            uvIndexCategory: weatherKitCurrentWeather.uvIndex.category.description,
            precipitationIntensity: weatherKitCurrentWeather.precipitationIntensity,
            precipitationChance: todayForecast?.precipitationChance, // Use today's precipitation chance from daily forecast
            precipitationChanceToday: precipitationChanceToday, // Calculated from hourly data for rest of today
            pressure: weatherKitCurrentWeather.pressure 
        )
        return customCurrentWeather
    }
    
    // Internal method to fetch and map daily forecast
    private func getSevenDayForecast(for location: CLLocation) async throws -> [DailyForecast] {
        // isLoadingForecast and weatherError are handled by the public fetchWeather method
        print("[WeatherService] getSevenDayForecast called for location: \(location.coordinate)") // DEBUG
        let weatherKitDailyForecast = try await weatherService.weather(for: location, including: .daily)
        
        // Get hourly forecast to calculate precipitation chance for rest of today
        let hourlyForecast = try await weatherService.weather(for: location, including: .hourly)
        let precipitationChanceToday = calculatePrecipitationChanceForRestOfToday(hourlyForecast: hourlyForecast.forecast)
        
        // Get the start of the current day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Include today's forecast and take 7 days total
        let sevenDayForecasts = weatherKitDailyForecast.forecast
            .filter { dayWeather in
                // Include days starting from today
                return dayWeather.date >= today
            }
            .prefix(7) // Take 7 days total
            .map { dayWeather in
                let isToday = calendar.isDate(dayWeather.date, inSameDayAs: Date())
                return DailyForecast(
                    date: dayWeather.date,
                    highTemperature: dayWeather.highTemperature,
                    lowTemperature: dayWeather.lowTemperature,
                    conditionSymbolName: dayWeather.symbolName,
                    conditionDescription: dayWeather.condition.description,
                    precipitationChance: dayWeather.precipitationChance,
                    precipitationChanceToday: isToday ? precipitationChanceToday : nil
                )
            }
        
        print("[WeatherService] getSevenDayForecast: Successfully mapped and trimmed to 7-day forecast starting from today.") // DEBUG
        return Array(sevenDayForecasts)
    }
    
    // Internal method to fetch and map hourly forecast for today
    private func getHourlyForecast(for location: CLLocation) async throws -> [HourlyForecast] {
        print("[WeatherService] getHourlyForecast called for location: \(location.coordinate)") // DEBUG
        let weatherKitHourlyForecast = try await weatherService.weather(for: location, including: .hourly)
        
        // Get the current time and end of today
        let calendar = Calendar.current
        let now = Date()
        let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now.addingTimeInterval(86400)
        
        // Include hours from now until end of today (next 12-24 hours depending on current time)
        let todayHourlyForecasts = weatherKitHourlyForecast.forecast
            .filter { hourWeather in
                // Include hours from now until end of today
                return hourWeather.date >= now && hourWeather.date <= endOfToday
            }
            .prefix(12) // Limit to next 12 hours for better display
            .map { hourWeather in
                HourlyForecast(
                    date: hourWeather.date,
                    temperature: hourWeather.temperature,
                    conditionSymbolName: hourWeather.symbolName,
                    conditionDescription: hourWeather.condition.description,
                    precipitationChance: hourWeather.precipitationChance
                )
            }
        
        print("[WeatherService] getHourlyForecast: Successfully mapped hourly forecast for today.") // DEBUG
        return Array(todayHourlyForecasts)
    }
    
    // Helper method to calculate precipitation chance for the rest of today
    private func calculatePrecipitationChanceForRestOfToday(hourlyForecast: [WeatherKit.HourWeather]) -> Double? {
        let calendar = Calendar.current
        let now = Date()
        let endOfToday = calendar.dateInterval(of: .day, for: now)?.end ?? now.addingTimeInterval(86400)
        
        // Get hourly forecasts from now until end of today
        let remainingHours = hourlyForecast.filter { hourWeather in
            hourWeather.date >= now && hourWeather.date <= endOfToday
        }
        
        // If no remaining hours in the day, return nil
        guard !remainingHours.isEmpty else { return nil }
        
        // Calculate the maximum precipitation chance from all remaining hours
        let maxPrecipitationChance = remainingHours.map { $0.precipitationChance }.max() ?? 0.0
        
        return maxPrecipitationChance
    }
}

// MARK: - Data Models

struct CurrentWeather: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let temperature: Measurement<UnitTemperature>
    let conditionDescription: String
    let conditionSymbolName: String
    let feelsLikeTemperature: Measurement<UnitTemperature>
    let windSpeed: Measurement<UnitSpeed>
    let windDirection: Measurement<UnitAngle>?
    let humidityFraction: Double // 0.0 to 1.0
    let uvIndexValue: Int
    let uvIndexCategory: String // e.g., "Low", "Moderate", "High"
    let precipitationIntensity: Measurement<UnitSpeed>? // e.g., mm/hr
    let precipitationChance: Double? // 0.0 to 1.0, for the current hour/period
    let precipitationChanceToday: Double? // 0.0 to 1.0, for the rest of today
    let pressure: Measurement<UnitPressure> 
}

struct DailyForecast: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let highTemperature: Measurement<UnitTemperature>
    let lowTemperature: Measurement<UnitTemperature>
    let conditionSymbolName: String
    let conditionDescription: String
    let precipitationChance: Double
    let precipitationChanceToday: Double? // For today's row, calculated from remaining hours
}

struct HourlyForecast: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let temperature: Measurement<UnitTemperature>
    let conditionSymbolName: String
    let conditionDescription: String
    let precipitationChance: Double
}

// MARK: - Symbol Name Utilities

private func filledSymbolName(for symbolName: String) -> String {
    // Map common WeatherKit symbol names to their filled variants
    switch symbolName {
    case "sun.max":
        return "sun.max.fill"
    case "sun.min":
        return "sun.min.fill"
    case "cloud":
        return "cloud.fill"
    case "cloud.sun":
        return "cloud.sun.fill"
    case "cloud.moon":
        return "cloud.moon.fill"
    case "cloud.rain":
        return "cloud.rain.fill"
    case "cloud.drizzle":
        return "cloud.drizzle.fill"
    case "cloud.heavyrain":
        return "cloud.heavyrain.fill"
    case "cloud.snow":
        return "cloud.snow.fill"
    case "cloud.sleet":
        return "cloud.sleet.fill"
    case "cloud.hail":
        return "cloud.hail.fill"
    case "cloud.bolt":
        return "cloud.bolt.fill"
    case "cloud.bolt.rain":
        return "cloud.bolt.rain.fill"
    case "smoke":
        return "smoke.fill"
    case "wind":
        return "wind"
    case "tornado":
        return "tornado"
    case "moon":
        return "moon.fill"
    case "moon.stars":
        return "moon.stars.fill"
    default:
        // If already has .fill suffix or is unknown, return as-is
        return symbolName
    }
}
