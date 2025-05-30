import SwiftUI

struct AboutView: View {
    // Get app version and build number
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        List {
            // App Info Section
            Section {
                VStack(alignment: .center, spacing: 20) {
                    Image(systemName: "cloud.sun.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                    
                    Text("SimpleWeather")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version \(appVersion) (\(buildNumber))")
                        .foregroundColor(.secondary)
                    
                    Text("Stay informed about the weather in your area with a clean and simple interface.")
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 20)
            }
            
            // Links Section
            Section(header: Text("Information")) {
                if let url = URL(string: "https://www.apple.com/weather/") {
                    Link("Weather Data Source: Apple Weather", destination: url)
                        .foregroundColor(.blue)
                }
                
                if let privacyURL = URL(string: "https://www.apple.com/legal/privacy/") {
                    Link("Privacy Policy", destination: privacyURL)
                        .foregroundColor(.blue)
                }
                
                if let termsURL = URL(string: "https://www.apple.com/legal/internet-services/terms/site.html") {
                    Link("Terms of Use", destination: termsURL)
                        .foregroundColor(.blue)
                }
            }
            
            // Developer Section
            Section(header: Text("Developer")) {
                HStack {
                    Text("Developed by")
                    Text("Farley Caesar")
                        .fontWeight(.medium)
                }
                
                if let url = URL(string: "https://github.com/yourusername/simpleweather") {
                    Link("View on GitHub", destination: url)
                        .foregroundColor(.blue)
                }
            }
            
            // Legal Section
            Section(footer: Text("© \(Calendar.current.component(.year, from: Date())) SimpleWeather. All weather data provided by Apple Weather.")) {
                // Empty section with footer
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        AboutView()
    }
}
