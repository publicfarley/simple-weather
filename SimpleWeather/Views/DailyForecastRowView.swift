import SwiftUI

struct DailyForecastRowView: View {
    let forecast: DailyForecast

    var body: some View {
        HStack(spacing: 16) {
            // Day of the week
            Text(forecast.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.subheadline)
                .frame(width: 50, alignment: .leading)
            
            // Weather icon
            Image(systemName: forecast.conditionSymbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
                .frame(width: 30, alignment: .center)
                .accessibilityLabel(Text(forecast.conditionDescription))
            
            // Temperature range as text
            HStack(spacing: 4) {
                Text("\(Int(forecast.highTemperature.value.rounded()))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(Int(forecast.lowTemperature.value.rounded()))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(forecast.highTemperature.unit.symbol)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Always show precipitation chance
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .accessibilityHidden(true)
                    .foregroundColor(forecast.precipitationChance > 0 ? .blue : .secondary)
                    .imageScale(.small)
                Text("\(Int(forecast.precipitationChance * 100))%")
                    .font(.caption)
                    .foregroundColor(forecast.precipitationChance > 0 ? .blue : .secondary)
            }
            .frame(width: 50, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
