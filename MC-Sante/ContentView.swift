import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    let healthKit: HealthKitService
    let weather: WeatherDataService
    let notifications: NotificationService
    let snapshotService: SnapshotService

    @State private var selectedTab: Tab = .home

    enum Tab: Int {
        case home, settings
    }

    var body: some View {
        if hasCompletedOnboarding {
            mainTabView
        } else {
            OnboardingView(
                healthKit: healthKit,
                weather: weather,
                notifications: notifications
            )
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(snapshotService: snapshotService, onSettingsTap: { selectedTab = .settings })
                .tabItem {
                    Label(L10n.tabHome, systemImage: "house.fill")
                }
                .tag(Tab.home)

            SettingsView(
                notificationService: notifications,
                healthKit: healthKit,
                weather: weather
            )
            .tabItem {
                Label(L10n.tabSettings, systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
    }
}
