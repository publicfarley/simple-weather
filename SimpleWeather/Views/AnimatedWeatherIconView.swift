import SwiftUI

// Helper structs for particles
struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat = 0
    var y: CGFloat = 0
    var opacity: Double = 0
    var scale: CGFloat = 1
    var rotation: Angle = .degrees(0)
    var isRainDrop: Bool = false // Differentiate shape
}

struct AnimatedWeatherIconView: View {
    let symbolName: String
    
    @State private var isPulsing: Bool = false
    @State private var sunRotationAngle: Angle = .degrees(0)
    @State private var particles: [Particle] = []
    
    // Constants for particle animations
    private let numberOfRainDrops = 7 // Increased for better visual
    private let numberOfSnowFlakes = 10 // Increased for better visual
    private let animationAreaHeight: CGFloat = 60 // Area below the icon for particles to fall
    private let iconSize: CGFloat = 70

    var body: some View {
        let baseImage = Image(systemName: symbolName)
            .font(.system(size: iconSize))
            .symbolRenderingMode(.multicolor)

        ZStack { // Use ZStack to overlay particles on the icon
            Group {
                switch symbolName {
                case "sun.max.fill":
                    baseImage
                        .rotationEffect(sunRotationAngle)
                case "cloud.rain.fill", "cloud.drizzle.fill", "cloud.heavyrain.fill":
                    baseImage // Cloud icon
                    // Raindrops will be drawn by the common particle renderer
                case "snow", "cloud.snow.fill", "wind.snow":
                    baseImage // Snowflake icon or cloud
                    // Snowflakes will be drawn by the common particle renderer
                default:
                    baseImage
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .opacity(isPulsing ? 0.8 : 1.0)
                }
            }
            
            // Particle Renderer
            ForEach(particles) { particle in
                if particle.isRainDrop {
                    Capsule()
                        .fill(LinearGradient(colors: [.blue.opacity(0.8), .blue.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                        .frame(width: 2.5, height: 12) // Slightly thicker and longer drops
                        .offset(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                        //.scaleEffect(particle.scale) // Raindrops usually don't scale much
                } else { // Snowflake
                    Image(systemName: "snowflake") 
                        .font(.system(size: CGFloat.random(in: 8...15))) // Varied snowflake size
                        .foregroundColor(.white.opacity(0.9))
                        .offset(x: particle.x, y: particle.y)
                        .opacity(particle.opacity)
                        .scaleEffect(particle.scale)
                        .rotationEffect(particle.rotation)
                }
            }
        }
        .frame(width: iconSize * 1.5, height: iconSize + animationAreaHeight) // Define a frame for animations
        .onAppear(perform: setupAnimations)
        // Add .onChange to re-setup animations if the symbolName changes while view is visible
        .onChange(of: symbolName) {
            setupAnimations()
        }
    }
    
    private func setupAnimations() {
        // Reset all animation states
        isPulsing = false
        sunRotationAngle = .degrees(0)
        particles = [] // Clear previous particles
        
        // Use DispatchQueue.main.async to ensure state changes are processed before animation starts
        // This can be helpful if setupAnimations is called rapidly (e.g., via onChange)
        DispatchQueue.main.async {
            switch symbolName {
            case "sun.max.fill":
                withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                    self.sunRotationAngle = .degrees(360)
                }
                
            case "cloud.rain.fill", "cloud.drizzle.fill", "cloud.heavyrain.fill":
                self.particles = (0..<numberOfRainDrops).map { _ in
                    Particle(
                        x: CGFloat.random(in: -iconSize/3...iconSize/3), 
                        y: CGFloat.random(in: -10...0), // Start near cloud base
                        opacity: 0,
                        isRainDrop: true
                    )
                }
                for i in particles.indices {
                    // Ensure we don't go out of bounds if particles array changes unexpectedly
                    if particles.indices.contains(i) { animateRainDrop(index: i) }
                }

            case "snow", "cloud.snow.fill", "wind.snow":
                self.particles = (0..<numberOfSnowFlakes).map { _ in
                    Particle(
                        x: CGFloat.random(in: -iconSize/2...iconSize/2),
                        y: CGFloat.random(in: -10...0), // Start near top
                        opacity: 0,
                        scale: CGFloat.random(in: 0.6...1.3),
                        rotation: .degrees(Double.random(in: 0...360)),
                        isRainDrop: false
                    )
                }
                for i in particles.indices {
                    if particles.indices.contains(i) { animateSnowFlake(index: i) }
                }
                
            default:
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    self.isPulsing = true
                }
            }
        }
    }

    private func animateRainDrop(index: Int) {
        guard particles.indices.contains(index), particles[index].isRainDrop else { return }
        
        particles[index].y = CGFloat.random(in: -5...5) // Start just below cloud center
        particles[index].opacity = 0

        let delay = Double.random(in: 0...1.2) 
        let fallDuration = Double.random(in: 0.4...0.8)

        // Phase 1: Fade in and start falling
        withAnimation(Animation.easeIn(duration: fallDuration * 0.3).delay(delay)) {
            if particles.indices.contains(index) {
                particles[index].opacity = 1.0
                particles[index].y += animationAreaHeight * 0.3 
            }
        }

        // Phase 2: Fall to bottom and fade out
        withAnimation(Animation.linear(duration: fallDuration * 0.7).delay(delay + fallDuration * 0.3)) {
            if particles.indices.contains(index) {
                particles[index].y = animationAreaHeight 
                particles[index].opacity = 0 
            }
        } completion: {
            if particles.indices.contains(index), particles[index].isRainDrop, symbolName.contains("cloud.rain") || symbolName.contains("drizzle") || symbolName.contains("heavyrain") {
                 animateRainDrop(index: index)
            }
        }
    }

    private func animateSnowFlake(index: Int) {
        guard particles.indices.contains(index), !particles[index].isRainDrop else { return }

        particles[index].x = CGFloat.random(in: -iconSize/1.8...iconSize/1.8) 
        particles[index].y = CGFloat.random(in: -15...0) 
        particles[index].opacity = 0
        particles[index].scale = CGFloat.random(in: 0.6...1.3)
        particles[index].rotation = .degrees(Double.random(in: -45...45)) // Start with some rotation

        let delay = Double.random(in: 0...2.5) 
        let fallDuration = Double.random(in: 2.5...5.0)
        let swayAmount = CGFloat.random(in: -20...20)
        let rotationChange = Angle.degrees(Double.random(in: -270...270))

        // Phase 1: Fade in, start falling
        withAnimation(Animation.easeIn(duration: fallDuration * 0.4).delay(delay)) {
            if particles.indices.contains(index) {
                particles[index].opacity = Double.random(in: 0.7...1.0)
                particles[index].y += animationAreaHeight * 0.4
                particles[index].x += swayAmount * 0.4
                particles[index].rotation += rotationChange * 0.4
            }
        }

        // Phase 2: Continue falling, swaying, rotating, then fade out
        withAnimation(Animation.linear(duration: fallDuration * 0.6).delay(delay + fallDuration * 0.4)) {
            if particles.indices.contains(index) {
                particles[index].y = animationAreaHeight 
                particles[index].x += swayAmount
                particles[index].opacity = 0
                particles[index].rotation += rotationChange
                particles[index].scale *= CGFloat.random(in: 0.7...0.9) // Shrink a bit
            }
        } completion: {
            if particles.indices.contains(index), !particles[index].isRainDrop, symbolName.contains("snow") {
                animateSnowFlake(index: index)
            }
        }
    }
}

// MARK: - Previews

#Preview("Sunny (Rotating)", traits: .sizeThatFitsLayout) {
    VStack {
        Text("Sunny (Rotating):").font(.headline)
        AnimatedWeatherIconView(symbolName: "sun.max.fill")
    }
    .padding()
    .background(Color.blue.opacity(0.2))
}

#Preview("Rainy (Particles)", traits: .sizeThatFitsLayout) {
    VStack {
        Text("Rainy (Particles):").font(.headline)
        AnimatedWeatherIconView(symbolName: "cloud.rain.fill")
    }
    .padding()
    .background(Color.blue.opacity(0.2))
}

#Preview("Snowy (Particles)", traits: .sizeThatFitsLayout) {
    VStack {
        Text("Snowy (Particles):").font(.headline)
        AnimatedWeatherIconView(symbolName: "snow")
    }
    .padding()
    .background(Color.blue.opacity(0.2))
}

#Preview("Windy (Pulsing)", traits: .sizeThatFitsLayout) {
    VStack {
        Text("Windy (Pulsing):").font(.headline)
        AnimatedWeatherIconView(symbolName: "wind")
    }
    .padding()
    .background(Color.blue.opacity(0.2))
}

#Preview("All Weather Icons", traits: .sizeThatFitsLayout) {
    ScrollView {
        VStack(spacing: 30) {
            Group {
                Text("Sunny (Rotating):").font(.headline)
                AnimatedWeatherIconView(symbolName: "sun.max.fill")
                Divider()
                Text("Rainy (Particles):").font(.headline)
                AnimatedWeatherIconView(symbolName: "cloud.rain.fill")
                Divider()
                Text("Snowy (Particles):").font(.headline)
                AnimatedWeatherIconView(symbolName: "snow")
                Divider()
                Text("Windy (Pulsing):").font(.headline)
                AnimatedWeatherIconView(symbolName: "wind")
                Divider()
                Text("Cloudy (Pulsing):").font(.headline)
                AnimatedWeatherIconView(symbolName: "cloud.fill")
            }
            .padding()
        }
    }
    .frame(height: 800)
    .background(Color.blue.opacity(0.2))
}
