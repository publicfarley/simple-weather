import SwiftUI

struct AnimatedWeatherIconView: View {
    let symbolName: String
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: 70)) // Default size, can be customized
            .symbolRenderingMode(.multicolor) // For colorful SF Symbols
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(isAnimating ? 0.8 : 1.0)
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
    }
}

#if DEBUG
struct AnimatedWeatherIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            AnimatedWeatherIconView(symbolName: "sun.max.fill") // Sunny
            AnimatedWeatherIconView(symbolName: "cloud.rain.fill") // Rainy
            AnimatedWeatherIconView(symbolName: "snowflake") // Snowy
        }
        .padding()
    }
}
#endif
