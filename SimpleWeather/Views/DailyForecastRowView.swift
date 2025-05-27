import SwiftUI

struct DailyForecastRowView: View {
    let forecast: DailyForecast

    var body: some View {
        HStack {
            Text(forecast.date.formatted(.dateTime.weekday(.abbreviated)))
                .frame(width: 50, alignment: .leading)
            
            Spacer()
            
            Image(systemName: forecast.conditionSymbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
                .accessibilityLabel(Text(forecast.conditionDescription))
            
            Spacer()
            
            Text("H: \(forecast.highTemperature.formatted(.measurement(width: .narrow, usage: .weather)))")
            Text("L: \(forecast.lowTemperature.formatted(.measurement(width: .narrow, usage: .weather)))")
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Precipitation Chance
            if forecast.precipitationChance > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .accessibilityHidden(true)
                        .foregroundColor(.blue)
                    Text("\(forecast.precipitationChance, format: .percent.precision(.fractionLength(0)))")
                }
                .font(.caption)
            } else {
                // Optional: Show empty space or a different icon if no precipitation
                // For now, let's keep it clean and show nothing if chance is 0
                Spacer().frame(width: 50) // Keep alignment consistent if no precip
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
struct DailyForecastRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DailyForecastRowView(forecast: ForecastView_Previews.previewForecastData[0])
            DailyForecastRowView(forecast: ForecastView_Previews.previewForecastData[1])
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
