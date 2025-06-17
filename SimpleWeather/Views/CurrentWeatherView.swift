import SwiftUI
import Combine
import CoreLocation

struct CurrentWeatherView: View {
    let currentWeather: CurrentWeather
    let location: CLLocation
    
    init(currentWeather: CurrentWeather, location: CLLocation) {
        self.currentWeather = currentWeather
        self.location = location
    }
    
    @State private var locationName: String = "Current Location"
    
    // Geocoder to convert coordinates to location name
    private let geocoder = CLGeocoder()
    
    // Function to format precipitation intensity from m/s to mm/h
    private func formatPrecipitation(_ precipitation: Measurement<UnitSpeed>) -> String {
        // Convert to meters per second if it's not already
        let metersPerSecond = precipitation.converted(to: .metersPerSecond).value
        
        // Convert from m/s to mm/h (1 m/s = 3600 mm/h)
        let mmPerHour = metersPerSecond * 3600
        
        // Format with appropriate precision
        if mmPerHour < 0.1 {
            return "Trace"
        } else if mmPerHour < 1.0 {
            return String(format: "%.1f mm/h", mmPerHour)
        } else {
            return String(format: "%.0f mm/h", mmPerHour)
        }
    }
    
    // Function to convert coordinates to location name
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    // Fallback to coordinates when geocoding fails
                    let lat = location.coordinate.latitude
                    let lon = location.coordinate.longitude
                    self.locationName = String(format: "%.4f, %.4f", lat, lon)
                    return
                }
                
                if let placemark = placemarks?.first {
                    // Format the location name based on available information
                    if let locality = placemark.locality {
                        // City name available
                        self.locationName = locality
                        
                        // Add state/province for US/Canada locations
                        if let administrativeArea = placemark.administrativeArea, 
                           (placemark.country == "United States" || placemark.country == "Canada") {
                            self.locationName += ", \(administrativeArea)"
                        }
                        
                        // Add country for all locations
                        if let country = placemark.country {
                            self.locationName += ", \(country)"
                        }
                    } else if let name = placemark.name {
                        // Use the name if locality isn't available
                        self.locationName = name
                        
                        // Add country if available
                        if let country = placemark.country {
                            self.locationName += ", \(country)"
                        }
                    } else {
                        // Fallback to coordinates if no readable name is available
                        let lat = location.coordinate.latitude
                        let lon = location.coordinate.longitude
                        self.locationName = String(format: "%.4f, %.4f", lat, lon)
                    }
                } else {
                    // Fallback to coordinates when no placemarks are found
                    let lat = location.coordinate.latitude
                    let lon = location.coordinate.longitude
                    self.locationName = String(format: "%.4f, %.4f", lat, lon)
                }
            }
        }
    }
    
    // Function to determine icon color based on symbol name
    private func iconColor(for symbolName: String) -> Color {
        let lowercased = symbolName.lowercased()
        
        return if lowercased.contains("sun") {
            // Pastel orange
            Color.orange.opacity(0.7)
        } else if lowercased.contains("rain") || lowercased.contains("drizzle") || lowercased.contains("shower") {
            // Pastel blue
            Color.blue.opacity(0.6)
        } else if lowercased.contains("snow") || lowercased.contains("sleet") || lowercased.contains("ice") {
            // Pastel cyan
            Color.cyan.opacity(0.5)
            
        } else if lowercased.contains("cloud") || lowercased.contains("fog") || lowercased.contains("mist") {
            // Pastel gray
            Color.teal.opacity(0.6)
        } else {
            // Gentle pastel off-white
            Color.indigo.opacity(0.7)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
                
                Text(locationName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .onAppear {
                // Get location name when the view appears
                reverseGeocode(location: location)
            }

            HStack(alignment: .center, spacing: 8) {
                Text(currentWeather.temperature.roundedUp().formatted(.measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Spacer()
                
                AnimatedWeatherIconView(symbolName: currentWeather.conditionSymbolName)
                    .font(.system(size: 50))
                    .foregroundColor(iconColor(for: currentWeather.conditionSymbolName))
                    .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                    .minimumScaleFactor(0.5)
                    .accessibilityLabel(Text(currentWeather.conditionDescription))
            }
            
            Text(currentWeather.conditionDescription)
                .font(.title3)
                .minimumScaleFactor(0.8)
                .lineLimit(2)

            Text("Feels like: \(currentWeather.feelsLikeTemperature.roundedUp().formatted(.measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))))")
                .font(.callout)
                .foregroundColor(.secondary)
                .minimumScaleFactor(0.8)

            // Wind Speed and Direction
            HStack {
                Image(systemName: "wind").accessibilityHidden(true)
                Text("Wind: \(currentWeather.windSpeed.formatted(.measurement(width: .abbreviated, usage: .general)))")
                if let windDirection = currentWeather.windDirection {
                    Text("from \(windDirection.formatted(.measurement(width: .abbreviated, usage: .general)))")
                }
            }
            .font(.callout)
            .foregroundColor(.secondary)

            // Humidity
            HStack {
                Image(systemName: "humidity.fill").accessibilityHidden(true)
                Text("Humidity: \(currentWeather.humidityFraction, format: .percent.precision(.fractionLength(0)))")
            }
            .font(.callout)
            .foregroundColor(.secondary)

            // UV Index
            HStack {
                Image(systemName: "sun.max.trianglebadge.exclamationmark.fill").accessibilityHidden(true)
                Text("UV Index: \(currentWeather.uvIndexValue) (\(currentWeather.uvIndexCategory))")
            }
            .font(.callout)
            .foregroundColor(.secondary)

            // Precipitation
            HStack {
                Image(systemName: "drop.fill").accessibilityHidden(true)
                if let precipitationIntensity = currentWeather.precipitationIntensity, precipitationIntensity.value > 0 {
                    Text("Precipitation: \(formatPrecipitation(precipitationIntensity))")
                } else if let precipitationChanceToday = currentWeather.precipitationChanceToday, precipitationChanceToday > 0 {
                    Text("Precipitation: \(precipitationChanceToday, format: .percent.precision(.fractionLength(0))) chance today")
                } else {
                    Text("Precipitation: None expected")
                }
            }
            .font(.callout)
            .foregroundColor(.secondary)

            // More details will be added here for other sub-tasks
            
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}

// MARK: - Previews

private extension CurrentWeather {
    static var previewData: CurrentWeather {
        CurrentWeather(
            date: Date(),
            temperature: Measurement(value: 22, unit: .celsius),
            conditionDescription: "Mostly Sunny",
            conditionSymbolName: "sun.max.fill",
            feelsLikeTemperature: Measurement(value: 24, unit: .celsius),
            windSpeed: Measurement(value: 10, unit: .kilometersPerHour),
            windDirection: Measurement(value: 90, unit: .degrees),
            humidityFraction: 0.65,
            uvIndexValue: 5,
            uvIndexCategory: "Low",
            precipitationIntensity: Measurement<UnitSpeed>(value: 0.5, unit: .metersPerSecond),
            precipitationChance: 0.1,
            precipitationChanceToday: 0.25,
            pressure: Measurement(value: 1012, unit: UnitPressure.hectopascals)
        )
    }
}

#Preview("Sunny Weather") {
    CurrentWeatherView(currentWeather: .previewData, location: CLLocation(latitude: 37.7749, longitude: -122.4194))
        .padding()
}

#Preview("Rainy Weather") {
    let rainyWeather = CurrentWeather(
        date: Date(),
        temperature: Measurement(value: 18, unit: .celsius),
        conditionDescription: "Heavy Rain",
        conditionSymbolName: "cloud.rain.fill",
        feelsLikeTemperature: Measurement(value: 16, unit: .celsius),
        windSpeed: Measurement(value: 25, unit: .kilometersPerHour),
        windDirection: Measurement(value: 180, unit: .degrees),
        humidityFraction: 0.85,
        uvIndexValue: 2,
        uvIndexCategory: "Low",
        precipitationIntensity: Measurement<UnitSpeed>(value: 0.0014, unit: .metersPerSecond), // ~5mm/hr
        precipitationChance: 0.9,
        precipitationChanceToday: 0.75,
        pressure: Measurement(value: 1005, unit: UnitPressure.hectopascals)
    )
    
    CurrentWeatherView(currentWeather: rainyWeather, location: CLLocation(latitude: 40.7128, longitude: -74.0060))
        .padding()
}

