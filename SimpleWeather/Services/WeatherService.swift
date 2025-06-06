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
            conditionSymbolName: weatherKitCurrentWeather.symbolName,
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
