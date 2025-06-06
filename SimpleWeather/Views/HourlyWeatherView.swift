import SwiftUI

struct HourlyWeatherView: View {
    let hourlyForecasts: [HourlyForecast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Hourly Forecast")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(hourlyForecasts) { forecast in
                        HourlyForecastItemView(forecast: forecast)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}

struct HourlyForecastItemView: View {
    let forecast: HourlyForecast
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter
    }
    
    private var isCurrentHour: Bool {
        let calendar = Calendar.current
        let now = Date()
        return calendar.isDate(forecast.date, equalTo: now, toGranularity: .hour)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Time
            Text(isCurrentHour ? "Now" : timeFormatter.string(from: forecast.date))
                .font(.caption)
                .fontWeight(isCurrentHour ? .semibold : .regular)
                .foregroundColor(isCurrentHour ? .primary : .secondary)
                .frame(minWidth: 40)
            
            // Weather icon
            Image(systemName: forecast.conditionSymbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title2)
                .frame(height: 30)
                .accessibilityLabel(Text(forecast.conditionDescription))
            
            // Precipitation chance
            if forecast.precipitationChance > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                        .font(.caption2)
                        .accessibilityHidden(true)
                    Text("\(Int(forecast.precipitationChance * 100))%")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                .frame(minHeight: 16)
            } else {
                Spacer()
                    .frame(height: 16)
            }
            
            // Temperature
            Text("\(Int(forecast.temperature.value.rounded()))")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(forecast.temperature.unit.symbol)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(width: 60)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("""
            \(isCurrentHour ? "Now" : timeFormatter.string(from: forecast.date)), 
            \(forecast.conditionDescription), 
            \(Int(forecast.temperature.value.rounded())) degrees\(forecast.precipitationChance > 0 ? ", \(Int(forecast.precipitationChance * 100))% chance of precipitation" : "")
        """.replacingOccurrences(of: "  ", with: " ")))
    }
}

// MARK: - Previews

#Preview("Hourly Weather View") {
    let sampleHourlyForecasts = [
        HourlyForecast(
            date: Date(),
            temperature: Measurement(value: 22, unit: .celsius),
            conditionSymbolName: "sun.max.fill",
            conditionDescription: "Sunny",
            precipitationChance: 0.0
        ),
        HourlyForecast(
            date: Date().addingTimeInterval(3600),
            temperature: Measurement(value: 24, unit: .celsius),
            conditionSymbolName: "cloud.sun.fill",
            conditionDescription: "Partly Cloudy",
            precipitationChance: 0.1
        ),
        HourlyForecast(
            date: Date().addingTimeInterval(7200),
            temperature: Measurement(value: 25, unit: .celsius),
            conditionSymbolName: "cloud.fill",
            conditionDescription: "Cloudy",
            precipitationChance: 0.3
        ),
        HourlyForecast(
            date: Date().addingTimeInterval(10800),
            temperature: Measurement(value: 23, unit: .celsius),
            conditionSymbolName: "cloud.rain.fill",
            conditionDescription: "Rain",
            precipitationChance: 0.8
        ),
        HourlyForecast(
            date: Date().addingTimeInterval(14400),
            temperature: Measurement(value: 21, unit: .celsius),
            conditionSymbolName: "cloud.heavyrain.fill",
            conditionDescription: "Heavy Rain",
            precipitationChance: 0.9
        )
    ]
    
    HourlyWeatherView(hourlyForecasts: sampleHourlyForecasts)
        .padding()
}

#Preview("Single Hour Item") {
    let sampleForecast = HourlyForecast(
        date: Date(),
        temperature: Measurement(value: 22, unit: .celsius),
        conditionSymbolName: "sun.max.fill",
        conditionDescription: "Sunny",
        precipitationChance: 0.0
    )
    
    HourlyForecastItemView(forecast: sampleForecast)
        .padding()
}