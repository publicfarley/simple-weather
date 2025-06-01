//
//  SimpleWeatherApp.swift
//  SimpleWeather
//
//  Created by Farley Caesar on 2025-05-26.
//

import SwiftUI

@main
struct SimpleWeatherApp: App {
    @State private var isShowingSplash = true
    
    var body: some Scene {
        WindowGroup {
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
                ContentView()
            }
        }
    }
}
