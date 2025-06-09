//
//  SimpleWeatherApp.swift
//  SimpleWeather
//
//  Created by Farley Caesar on 2025-05-26.
//

import SwiftUI
import SwiftData

@main
struct SimpleWeatherApp: App {
    @State private var isShowingSplash = true
    
    let container: ModelContainer
    @State private var locationStorage: LocationStorage?
    @State private var locationCache: LocationCache?
    @State private var locationManager: LocationManager?
    @State private var geocodingService: GeocodingService?
    
    init() {
        do {
            container = try ModelContainer(for: SavedLocation.self, CachedLocation.self)
        } catch {
            fatalError("Failed to configure SwiftData container: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isShowingSplash {
                    SplashScreenView()
                        .onAppear {
                            // Dismiss splash screen after 3 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isShowingSplash = false
                                }
                            }
                        }
                } else {
                    if let locationStorage = locationStorage,
                       let locationManager = locationManager,
                       let geocodingService = geocodingService {
                        LocationTabView()
                            .environment(locationStorage)
                            .environment(locationManager)
                            .environment(geocodingService)
                    } else {
                        ProgressView("Loading...")
                    }
                }
            }
            .onAppear {
                setupServices()
            }
        }
        .modelContainer(container)
    }
    
    private func setupServices() {
        let context = container.mainContext
        
        self.locationStorage = LocationStorage(modelContext: context)
        self.locationCache = LocationCache(modelContext: context)
        self.geocodingService = GeocodingService()
        
        if let cache = locationCache {
            self.locationManager = LocationManager(locationCache: cache)
        }
    }
}
