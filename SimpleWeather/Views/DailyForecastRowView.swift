import SwiftUI

struct DailyForecastRowView: View {
    let forecast: DailyForecast

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Day of the week
            Text(Calendar.current.isDateInToday(forecast.date) ? "Today" : forecast.date.formatted(.dateTime.weekday(.abbreviated)))
                .font(.subheadline)
                .frame(width: 65, alignment: .leading)
                .accessibilityLabel(Text(Calendar.current.isDateInToday(forecast.date) ? "Today" : forecast.date.formatted(.dateTime.weekday(.wide))))
            
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
                let precipChance = forecast.precipitationChanceToday ?? forecast.precipitationChance
                Image(systemName: "drop.fill")
                    .accessibilityHidden(true)
                    .foregroundColor(precipChance > 0 ? .blue : .secondary)
                    .imageScale(.small)
                    .frame(width: 15, alignment: .center)
                Text("\(Int(precipChance * 100))%")
                    .font(.caption2)
                    .foregroundColor(precipChance > 0 ? .blue : .secondary)
                    .lineLimit(1)
                    .frame(width: 38, alignment: .trailing)
            }
            .frame(width: 55, alignment: .trailing)
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("""
            \(Calendar.current.isDateInToday(forecast.date) ? "Today" : forecast.date.formatted(.dateTime.weekday(.wide))),
            \(forecast.conditionDescription), 
            high of \(Int(forecast.highTemperature.value.rounded())) degrees, 
            low of \(Int(forecast.lowTemperature.value.rounded())) degrees\({
                let precipChance = forecast.precipitationChanceToday ?? forecast.precipitationChance
                return precipChance > 0 ? ", \(Int(precipChance * 100))% chance of precipitation" : ""
            }())
        """.replacingOccurrences(of: "  ", with: " ")))
    }
}

// MARK: - Previews

#Preview("Sunny Day", traits: .sizeThatFitsLayout) {
    DailyForecastRowView(forecast: DailyForecast(
        date: Date(),
        highTemperature: Measurement(value: 25, unit: .celsius),
        lowTemperature: Measurement(value: 15, unit: .celsius),
        conditionSymbolName: "sun.max.fill",
        conditionDescription: "Sunny",
        precipitationChance: 0.1,
        precipitationChanceToday: 0.05
    ))
    .padding()
}

#Preview("Rainy Day", traits: .sizeThatFitsLayout) {
    DailyForecastRowView(forecast: DailyForecast(
        date: Date().addingTimeInterval(86400), // Tomorrow
        highTemperature: Measurement(value: 18, unit: .celsius),
        lowTemperature: Measurement(value: 12, unit: .celsius),
        conditionSymbolName: "cloud.rain.fill",
        conditionDescription: "Rainy",
        precipitationChance: 0.8,
        precipitationChanceToday: nil
    ))
    .padding()
}
