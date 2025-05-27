import SwiftUI

struct CurrentWeatherView: View {
    let currentWeather: CurrentWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Now")
                .font(.subheadline)
                .foregroundColor(.secondary)

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

#if DEBUG
struct CurrentWeatherView_Previews: PreviewProvider {
    static var previews: some View {
        CurrentWeatherView(currentWeather: previewWeatherData)
            .padding()
    }
    
    static var previewWeatherData: CurrentWeather {
        return CurrentWeather(
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
            precipitationIntensity: Measurement(value: 0.5, unit: .metersPerSecond),
            precipitationChance: 0.1,
            pressure: Measurement(value: 1012, unit: UnitPressure.hectopascals)
        )
    }
}
#endif
