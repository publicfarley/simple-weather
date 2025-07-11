import SwiftUI

struct AboutView: View {
    @Binding var showingAbout: Bool
    @State private var animateContent = false
    
    // Get app version and build number
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ZStack {
            StarfieldView()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // App Info Section
                    VStack {
                VStack(alignment: .center, spacing: 20) {
                    Image(systemName: "cloud.sun.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.cyan)
                        .scaleEffect(animateContent ? 1.0 : 0.5)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateContent)
                    
                    Text("SimpleWeather")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.6).delay(0.2), value: animateContent)
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.6).delay(0.3), value: animateContent)
                    
                    Text("Stay informed about the weather in your area with a clean and simple interface.")
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .offset(y: animateContent ? 0 : 20)
                        .animation(.easeInOut(duration: 0.6).delay(0.4), value: animateContent)
                        }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                    }
            
                    // Links Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Information")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.bottom, 5)
                        
                        HStack {
                            if let url = URL(string: "https://www.apple.com/weather/") {
                                Link("Weather Data Source: Apple Weather", destination: url)
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                            }
                            Spacer()
                        }
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.easeInOut(duration: 0.6).delay(0.5), value: animateContent)
            
                    // Developer Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Developer")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.bottom, 5)
                        
                        HStack {
                            Text("Developed by")
                                .foregroundColor(.white)
                            Text("Farley Caesar")   
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.easeInOut(duration: 0.6).delay(0.6), value: animateContent)
            
                    // Legal Section
                    VStack {
                        Text("© \(String(format: "%d", Calendar.current.component(.year, from: Date()))) SimpleWeather. All weather data provided by Apple Weather.")
                            .foregroundColor(.gray)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                // Empty section with footer
                    }
                    .opacity(animateContent ? 1.0 : 0.0)
                    .offset(y: animateContent ? 0 : 30)
                    .animation(.easeInOut(duration: 0.6).delay(0.7), value: animateContent)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
                .padding()
                .scaleEffect(animateContent ? 1.0 : 0.9)
                .opacity(animateContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5), value: animateContent)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation {
                animateContent = true
            }
        }
    }
}

#Preview {
    AboutView(showingAbout: .constant(true))
}
