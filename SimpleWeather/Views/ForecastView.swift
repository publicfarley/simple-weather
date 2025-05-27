import SwiftUI

struct ForecastView: View {
    let dailyForecasts: [DailyForecast]

    var body: some View {
        VStack(alignment: .leading) {
            Text("7-Day Forecast")
                .font(.title2)
                .padding(.bottom, 5)

            if dailyForecasts.isEmpty {
                Text("Forecast data is not available.")
                    .foregroundColor(.secondary)
            } else {
                List(dailyForecasts) { forecast in
                    DailyForecastRowView(forecast: forecast)
                }
                .listStyle(.plain)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(15)
    }
}

#if DEBUG
struct ForecastView_Previews: PreviewProvider {
    static var previews: some View {
        ForecastView(dailyForecasts: previewForecastData)
            .padding()
    }
    
    static var previewForecastData: [DailyForecast] {
        var forecasts: [DailyForecast] = []
        for i in 0..<7 {
            forecasts.append(DailyForecast(
                date: Calendar.current.date(byAdding: .day, value: i, to: Date())!,
                highTemperature: Measurement(value: Double.random(in: 15...25), unit: .celsius),
                lowTemperature: Measurement(value: Double.random(in: 5...15), unit: .celsius),
                conditionSymbolName: ["sun.max.fill", "cloud.fill", "cloud.rain.fill", "cloud.snow.fill"].randomElement()!,
                conditionDescription: "Preview Condition",
                precipitationChance: Double.random(in: 0...1)
            ))
        }
        return forecasts
    }
}
#endif
