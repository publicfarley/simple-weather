import Foundation
import WeatherKit
import CoreLocation

@MainActor
class WeatherService: ObservableObject {
    private let weatherService = WeatherKit.WeatherService.shared

    @Published var currentWeather: CurrentWeather? = nil
    @Published var dailyForecast: [DailyForecast]? = nil
    @Published var isLoadingCurrentWeather: Bool = false
    @Published var isLoadingForecast: Bool = false
    @Published var weatherError: Error? = nil

    // Data models and methods will be added here

    init() {
        // Initialization code if needed
    }

    // Main method for ContentView to call
    func fetchWeather(for location: CLLocation) async {
        print("[WeatherService] fetchWeather called for location: \(location.coordinate)")
        isLoadingCurrentWeather = true
        isLoadingForecast = true
        weatherError = nil // Clear previous errors
        currentWeather = nil // Clear previous data
        dailyForecast = nil // Clear previous data
        defer {
            isLoadingCurrentWeather = false
            isLoadingForecast = false
        }

        do {
            async let current = getCurrentWeather(for: location)
            async let forecast = getSevenDayForecast(for: location)
            
            self.currentWeather = try await current
            self.dailyForecast = try await forecast
            print("[WeatherService] fetchWeather: Successfully fetched current weather and forecast.")
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
        
        let customCurrentWeather = CurrentWeather(
            date: weatherKitCurrentWeather.date,
            temperature: weatherKitCurrentWeather.temperature,
            conditionDescription: weatherKitCurrentWeather.condition.description,
            conditionSymbolName: weatherKitCurrentWeather.symbolName,
            feelsLikeTemperature: weatherKitCurrentWeather.apparentTemperature,
            windSpeed: weatherKitCurrentWeather.wind.speed,
            windDirection: weatherKitCurrentWeather.wind.direction,
            humidityFraction: weatherKitCurrentWeather.humidity,
            uvIndexValue: weatherKitCurrentWeather.uvIndex.value,
            uvIndexCategory: weatherKitCurrentWeather.uvIndex.category.description,
            precipitationIntensity: weatherKitCurrentWeather.precipitationIntensity,
            precipitationChance: nil, 
            pressure: weatherKitCurrentWeather.pressure 
        )
        return customCurrentWeather
    }
    
    // Internal method to fetch and map daily forecast
    private func getSevenDayForecast(for location: CLLocation) async throws -> [DailyForecast] {
        // isLoadingForecast and weatherError are handled by the public fetchWeather method
        print("[WeatherService] getSevenDayForecast called for location: \(location.coordinate)") // DEBUG
        let weatherKitDailyForecast = try await weatherService.weather(for: location, including: .daily)
        
        // Get the start of the next day
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: Date()).addingTimeInterval(86400) // Add 24 hours to get start of next day
        
        // Filter out today's forecast and take the next 7 days
        let nextSevenDaysForecasts = weatherKitDailyForecast.forecast
            .filter { dayWeather in
                // Only include days that are at least the start of tomorrow
                return dayWeather.date >= tomorrow
            }
            .prefix(7) // Take the next 7 days
            .map { dayWeather in
                DailyForecast(
                    date: dayWeather.date,
                    highTemperature: dayWeather.highTemperature,
                    lowTemperature: dayWeather.lowTemperature,
                    conditionSymbolName: dayWeather.symbolName,
                    conditionDescription: dayWeather.condition.description,
                    precipitationChance: dayWeather.precipitationChance
                )
            }
        
        print("[WeatherService] getSevenDayForecast: Successfully mapped and trimmed to 7-day forecast starting from tomorrow.") // DEBUG
        return Array(nextSevenDaysForecasts)
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
}
