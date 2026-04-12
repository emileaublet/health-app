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
            HomeView(snapshotService: snapshotService)
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }
                .tag(Tab.home)

            LogView()
                .tabItem {
                    Label("Saisie", systemImage: "pencil.circle.fill")
                }
                .tag(Tab.log)

            TrendsView()
                .tabItem {
                    Label("Tendances", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(Tab.trends)

            SettingsView(
                notificationService: notifications,
                healthKit: healthKit,
                weather: weather
            )
            .tabItem {
                Label("Réglages", systemImage: "gearshape.fill")
            }
            .tag(Tab.settings)
        }
    }
}
