import SwiftUI

struct Star: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
    var angle: CGFloat // Direction angle in radians
}

struct StarfieldView: View {
    @State private var stars: [Star] = []
    @State private var timer: Timer? = nil
    private let starCount = 100
    private let minSize: CGFloat = 2 // Reduced from 4 to 2
    private let maxSize: CGFloat = 6 // Reduced from 12 to 6
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                
                ForEach(stars) { star in
                    Circle()
                        .fill(Color.white)
                        .frame(width: star.size, height: star.size)
                        .position(x: star.x, y: star.y)
                        .opacity(star.opacity)
                }
            }
            .onAppear {
                // Initialize stars across the entire view
                stars = (0..<starCount).map { _ in
                    createRandomStar(in: geometry.size)
                }
                
                // Start animation
                let size = geometry.size
                timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    withAnimation {
                        updateStars(in: size)
                    }
                }
            }
            .onDisappear {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func createRandomStar(in size: CGSize) -> Star {
        // Distribute stars across the entire view
        let startX = CGFloat.random(in: 0...size.width)
        let startY = CGFloat.random(in: 0...size.height)
        
        // Random direction angle (determines the trajectory)
        let directionAngle = CGFloat.random(in: 0...(2 * .pi))
        
        return Star(
            x: startX,
            y: startY,
            size: CGFloat.random(in: minSize...maxSize),
            opacity: Double.random(in: 0.2...1.0),
            speed: CGFloat.random(in: 1.0...3.0),
            angle: directionAngle
        )
    }
    
    private func updateStars(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        for i in 0..<stars.count {
            // Move stars away from the center to create a 'flying outward' effect
            let directionX = stars[i].x - centerX
            let directionY = stars[i].y - centerY
            let distance = sqrt(directionX * directionX + directionY * directionY)
            
            // Normalize direction and apply speed
            if distance > 0 {
                stars[i].x += (directionX / distance) * stars[i].speed
                stars[i].y += (directionY / distance) * stars[i].speed
            }
            
            // Increase size as stars get closer to center to create depth effect
            stars[i].size += 0.03
            
            // Calculate distance from center
            let distanceFromCenter = sqrt(pow(stars[i].x - centerX, 2) + pow(stars[i].y - centerY, 2))
            let maxDistance = sqrt(pow(size.width / 2, 2) + pow(size.height / 2, 2))
            
            // Fade out stars as they reach the edges
            if distanceFromCenter > maxDistance * 0.7 {
                stars[i].opacity -= 0.02 // Fade out faster when near edges
            }
            
            // If star goes off screen or becomes invisible, reset it at the center
            if stars[i].x < 0 || stars[i].x > size.width || 
               stars[i].y < 0 || stars[i].y > size.height || 
               stars[i].opacity <= 0 {
                
                // Reset star near center
                let startRadius = min(size.width, size.height) * 0.1
                let randomRadius = CGFloat.random(in: 0...startRadius)
                let randomAngle = CGFloat.random(in: 0...(2 * .pi))
                
                stars[i].x = centerX + randomRadius * cos(randomAngle)
                stars[i].y = centerY + randomRadius * sin(randomAngle)
                stars[i].size = CGFloat.random(in: minSize...maxSize)
                stars[i].opacity = Double.random(in: 0.2...1.0)
                stars[i].speed = CGFloat.random(in: 1.0...3.0)
                stars[i].angle = CGFloat.random(in: 0...(2 * .pi))
            }
        }
    }
}

#Preview {
    StarfieldView()
        .frame(width: 300, height: 500)
}
