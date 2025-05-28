import SwiftUI

struct ForecastView: View {
    let dailyForecasts: [DailyForecast]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if dailyForecasts.isEmpty {
                Text("Forecast data is not available.")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(dailyForecasts) { forecast in
                    DailyForecastRowView(forecast: forecast)
                    
                    // Add a divider between rows, except after the last one
                    if forecast.id != dailyForecasts.last?.id {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}

// MARK: - Previews

#Preview {
    ForecastView(dailyForecasts: ForecastView.previewForecastData)
        .padding()
}

private extension ForecastView {
    static var previewForecastData: [DailyForecast] {
        (0..<7).map { i in
            DailyForecast(
                date: Calendar.current.date(byAdding: .day, value: i, to: Date())!,
                highTemperature: Measurement(value: Double.random(in: 15...25), unit: .celsius),
                lowTemperature: Measurement(value: Double.random(in: 5...15), unit: .celsius),
                conditionSymbolName: ["sun.max.fill", "cloud.fill", "cloud.rain.fill", "cloud.snow.fill"].randomElement()!,
                conditionDescription: ["Sunny", "Cloudy", "Rainy", "Snowy"].randomElement()!,
                precipitationChance: Double.random(in: 0...1)
            )
        }
    }
}
