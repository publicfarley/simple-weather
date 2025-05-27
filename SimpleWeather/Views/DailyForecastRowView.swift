import SwiftUI

struct DailyForecastRowView: View {
    let forecast: DailyForecast

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Day of the week
            Text(forecast.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.subheadline)
                .frame(minWidth: 40, alignment: .leading)
                .accessibilityLabel(Text(forecast.date.formatted(.dateTime.weekday(.wide))))
            
            // Weather icon
            Image(systemName: forecast.conditionSymbolName)
                .symbolRenderingMode(.multicolor)
                .font(.title3)
                .frame(width: 30, alignment: .center)
                .accessibilityLabel(Text(forecast.conditionDescription))
                .accessibilityHidden(true) // Already read by the row's accessibility element
            
            // Temperature range as text
            HStack(spacing: 2) {
                Text("\(Int(forecast.highTemperature.value.rounded()))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text("\(Int(forecast.lowTemperature.value.rounded()))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(forecast.highTemperature.unit.symbol)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .minimumScaleFactor(0.7)
            
            // Always show precipitation chance
            HStack(spacing: 2) {
                Image(systemName: "drop.fill")
                    .accessibilityHidden(true)
                    .foregroundColor(forecast.precipitationChance > 0 ? .blue : .secondary)
                    .imageScale(.small)
                Text("\(Int(forecast.precipitationChance * 100))%")
                    .font(.caption2)
                    .foregroundColor(forecast.precipitationChance > 0 ? .blue : .secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 40, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("""
            \(forecast.date.formatted(.dateTime.weekday(.wide))), 
            \(forecast.conditionDescription), 
            high of \(Int(forecast.highTemperature.value.rounded())) degrees, 
            low of \(Int(forecast.lowTemperature.value.rounded())) degrees\(forecast.precipitationChance > 0 ? ", \(Int(forecast.precipitationChance * 100))% chance of precipitation" : "")
        """.replacingOccurrences(of: "  ", with: " ")))
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
