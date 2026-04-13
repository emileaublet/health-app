import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // Shared services injected from MC_SanteApp
    let healthKit: HealthKitService
    let weather: WeatherDataService
    let notifications: NotificationService
    let snapshotService: SnapshotService

    @State private var selectedTab: Tab = .home

    enum Tab: Int {
        case home, log, trends, settings
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
            HomeView(snapshotService: snapshotService, selectedTab: $selectedTab)
                .tabItem {
                    Label(L10n.tabHome, systemImage: "house.fill")
                }
                .tag(Tab.home)

            LogView()
                .tabItem {
                    Label(L10n.tabLog, systemImage: "pencil.circle.fill")
                }
                .tag(Tab.log)

            TrendsView()
                .tabItem {
                    Label(L10n.tabTrends, systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.trends)

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
