# Animated Weather App - Development Tasks

## Phase 1: Project Setup & Core Services
1.  **Project Initialization & Configuration:**
    *   [x] Create Xcode project (`SimpleWeather`).
    *   [x] Configure App ID with WeatherKit capability in Apple Developer Portal.
    *   [x] Add WeatherKit capability in Xcode's "Signing & Capabilities".
    *   [x] Add `Privacy - Location When In Use Usage Description` to target's "Info" tab.
2.  **Location Services Implementation (`LocationManager.swift`):**
    *   [x] Create `LocationManager.swift` file within a `Services` group.
    *   [x] Implement `CLLocationManagerDelegate` and basic properties (`location`, `isLoading`, `authorizationStatus`).
    *   [x] Implement `requestLocationPermission()` method.
    *   [x] Implement `requestLocation()` method for one-time fetch.
    *   [x] Handle `didUpdateLocations` delegate method.
    *   [x] Handle `didFailWithError` delegate method.
    *   [x] Handle `locationManagerDidChangeAuthorization` to react to permission changes and auto-fetch location if granted.
    *   [x] Ensure `LocationManager` is an `ObservableObject` for SwiftUI.
3.  **Weather Service Implementation (`WeatherService.swift`):**
    *   [x] Create `WeatherService.swift` file within the `Services` group.
    *   [x] Define Swift data models for:
        *   `CurrentWeather` (temperature, condition text, condition symbol, feels like, wind, humidity, UV index, precipitation).
        *   `DailyForecast` (date, high temp, low temp, condition symbol, precipitation chance).
    *   [x] Implement function to fetch current weather using `WeatherKit` and `CLLocationCoordinate2D`.
    *   [x] Implement function to fetch 7-day forecast using `WeatherKit` and `CLLocationCoordinate2D`.
    *   [x] Ensure `WeatherService` can handle API errors and loading states gracefully.
    *   [x] Make `WeatherService` an `ObservableObject` or provide async methods for SwiftUI.

## Phase 2: UI Development - Main Weather View
4.  **Main View Structure (`ContentView.swift` or `MainWeatherView.swift`):**
    *   [x] Set up `ContentView` to use `LocationManager` and `WeatherService` (e.g., as `@StateObject` or `@EnvironmentObject`).
    *   [x] Implement logic to:
        *   [x] Request location permission on appear if status is `notDetermined`.
        *   [x] Show a loading indicator while fetching location or weather.
        *   [x] Display an error message if location is denied or weather data fails to load.
        *   [x] Display primary weather info once data is available.
5.  **Current Weather Information Display:**
    *   [x] Display current temperature prominently.
    *   [x] Display "Feels like" temperature.
    *   [x] Display current weather condition text (e.g., "Sunny", "Cloudy").
    *   [x] Display wind speed and direction.
    *   [x] Display humidity percentage.
    *   [x] Display UV index.
    *   [x] Display precipitation chance/amount for the current period.
6.  **Current Weather Condition Animation/Icon:**
    *   [x] Create `AnimatedWeatherIconView.swift` (or similar reusable view).
    *   [x] Design/Source initial set of static icons or simple animations for key weather conditions (e.g., sunny, cloudy, rain, snow, wind).
    *   [x] Integrate `AnimatedWeatherIconView` into the main view to display based on the current weather condition symbol from WeatherKit.

## Phase 3: UI Development - 7-Day Forecast
7.  **Forecast View Structure:**
    *   [x] Create `ForecastView.swift` to display the 7-day forecast.
    *   [x] Integrate `ForecastView` into the main UI.
    *   [x] Display forecast data in a vertical list (`List`) or horizontal scroll (`ScrollView`).
8.  **Daily Forecast Item Display:**
    *   [x] Create `DailyForecastRowView.swift` for individual forecast days.
    *   [x] In `DailyForecastRowView`, display:
        *   [x] Day of the week (e.g., "Monday", "Tue").
        *   [x] High and low temperatures for the day.
        *   [x] A representative weather icon/symbol for the day's general condition.

## Phase 4: UI/UX Polish & Animations
9.  **Error Handling & Edge Cases:**
    *   [x] Improve error messages in `ContentView` for denied location or failed API calls (e.g., more user-friendly, retry options).
        *   [x] Add 'Open Settings' button for denied location access.
        *   [x] Add 'Retry' button for API call failures.
    *   [x] Handle scenarios where location is temporarily unavailable (e.g., airplane mode).
10. **Enhance Animations:**
    *   [x] Research and implement more engaging and smooth SwiftUI animations for:
        *   [x] Current weather condition (e.g., animated raindrops, moving clouds, shining sun).
        *   [x] Transitions between data loading states and content display.
    *   [x] Ensure animations are performant and don't negatively impact battery life.
11. **Refresh Mechanism:**
    *   [x] Implement a pull-to-refresh gesture or a manual refresh button to re-fetch weather data. (Manual button implemented)

## Phase 5: General & Non-Functional Requirements
12. **Accessibility (A11y):**
    *   [x] Ensure all UI elements have appropriate accessibility labels for VoiceOver.
    *   [x] Test with dynamic type sizes and ensure proper scaling.
    *   [x] Check color contrast for readability and ensure sufficient contrast ratios.
13. **App Icon:**
    *   [x] Design a playful app icon.
    *   [x] Add app icon to `Assets.xcassets`.

## Phase 6: Testing & Refinement
14. **Testing:**
    *   [ ] Manually test on different devices/simulators and iOS versions.
    *   [ ] Test edge cases (no internet, location off, slow network).
    *   [ ] Verify accessibility features on actual devices with different text size and VoiceOver settings.
    *   [ ] (Optional) Write Unit Tests for `LocationManager` and `WeatherService` logic.
    *   [ ] (Optional) Write UI Tests for key user flows.
15. **App Store Preparation:**
    *   [ ] Prepare screenshots.
    *   [ ] Write app description.
    *   [ ] Finalize bundle ID, version number.
