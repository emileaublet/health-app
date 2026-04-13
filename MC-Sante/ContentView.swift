import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let healthKit: HealthKitService
    let weather: WeatherDataService
    let notifications: NotificationService
    let snapshotService: SnapshotService

    @State private var showingSettings = false

    var body: some View {
        if hasCompletedOnboarding {
            HomeView(snapshotService: snapshotService, onSettingsTap: {
                showingSettings = true
            })
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    notificationService: notifications,
                    healthKit: healthKit,
                    weather: weather
                )
            }
        } else {
            OnboardingView(
                healthKit: healthKit,
                weather: weather,
                notifications: notifications
            )
        }
    }
}
