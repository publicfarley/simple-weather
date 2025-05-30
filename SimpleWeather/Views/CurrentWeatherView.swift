import SwiftUI
import Combine
import CoreLocation

struct CurrentWeatherView: View {
    let currentWeather: CurrentWeather
    var location: CLLocation?
    
    init(currentWeather: CurrentWeather, location: CLLocation? = nil) {
        self.currentWeather = currentWeather
        self.location = location
    }
    
    @State private var locationName: String = "Current Location"
    
    // Geocoder to convert coordinates to location name
    private let geocoder = CLGeocoder()
    
    // Function to convert coordinates to location name
    private func reverseGeocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    self.locationName = "Current Location"
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
                    } else if let name = placemark.name {
                        // Use the name if locality isn't available
                        self.locationName = name
                    } else {
                        // Fallback to coordinates if no readable name is available
                        let lat = location.coordinate.latitude
                        let lon = location.coordinate.longitude
                        self.locationName = String(format: "%.4f, %.4f", lat, lon)
                    }
                } else {
                    self.locationName = "Current Location"
                }
            }
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
                if let location = location {
                    reverseGeocode(location: location)
                }
            }

            HStack(alignment: .center, spacing: 8) {
                Text(currentWeather.temperature.roundedUp().formatted(.measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Spacer()
                
                AnimatedWeatherIconView(symbolName: currentWeather.conditionSymbolName)
                    .font(.system(size: 50))
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
                    Text("Precipitation: \(precipitationIntensity.formatted(.measurement(width: .abbreviated, usage: .general)))")
                } else if let precipitationChance = currentWeather.precipitationChance, precipitationChance > 0 {
                    Text("Precipitation: \(precipitationChance, format: .percent.precision(.fractionLength(0))) chance")
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
            pressure: Measurement(value: 1012, unit: UnitPressure.hectopascals)
        )
    }
}

#Preview("Sunny Weather") {
    CurrentWeatherView(currentWeather: .previewData)
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
        pressure: Measurement(value: 1005, unit: UnitPressure.hectopascals)
    )
    
    CurrentWeatherView(currentWeather: rainyWeather)
        .padding()
}
