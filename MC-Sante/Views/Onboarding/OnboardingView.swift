import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0

    let healthKit: HealthKitService
    let weather: WeatherDataService
    let notifications: NotificationService

    var body: some View {
        TabView(selection: $currentPage) {
            welcomePage.tag(0)
            healthKitPage.tag(1)
            locationPage.tag(2)
            notificationPage.tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .animation(.easeInOut, value: currentPage)
    }

    // MARK: Page 1 — Bienvenue

    private var welcomePage: some View {
        OnboardingPage(
            emoji: "🌱",
            title: L10n.welcomeTitle,
            description: L10n.welcomeDescription,
            primaryLabel: L10n.startButton,
            primaryAction: { currentPage = 1 }
        )
    }

    // MARK: Page 2 — HealthKit

    private var healthKitPage: some View {
        OnboardingPage(
            emoji: "❤️",
            title: L10n.healthDataTitle,
            description: L10n.healthDataDescription,
            secondaryLabel: L10n.maybeLater,
            secondaryAction: { currentPage = 2 },
            primaryLabel: L10n.authorizeAccessButton,
            primaryAction: {
                Task {
                    await healthKit.requestAuthorization()
                    currentPage = 2
                }
            }
        )
    }

    // MARK: Page 3 — Localisation

    private var locationPage: some View {
        OnboardingPage(
            emoji: "🌡️",
            title: L10n.weatherTitle,
            description: L10n.weatherDescription,
            secondaryLabel: L10n.skip,
            secondaryAction: { currentPage = 3 },
            primaryLabel: L10n.authorizeLocationButton,
            primaryAction: {
                weather.requestLocationPermission()
                currentPage = 3
            }
        )
    }

    // MARK: Page 4 — Notifications

    private var notificationPage: some View {
        OnboardingPage(
            emoji: "🔔",
            title: L10n.notificationsTitle,
            description: L10n.notificationsDescription,
            secondaryLabel: L10n.skip,
            secondaryAction: { complete() },
            primaryLabel: L10n.authorizeNotificationsButton,
            primaryAction: {
                Task {
                    await notifications.requestAuthorization()
                    if notifications.isAuthorized {
                        await notifications.scheduleDailyReminder(hour: 21, minute: 0)
                    }
                    complete()
                }
            }
        )
    }

    private func complete() {
        hasCompletedOnboarding = true
    }
}

// MARK: - OnboardingPage

private struct OnboardingPage: View {
    let emoji: String
    let title: String
    let description: String
    var secondaryLabel: String? = nil
    var secondaryAction: (() -> Void)? = nil
    let primaryLabel: String
    let primaryAction: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemBackground), Color.accentColor.opacity(0.06)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 120, height: 120)
                    Text(emoji)
                        .font(.system(size: 60))
                }

                VStack(spacing: 12) {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: primaryAction) {
                        Text(primaryLabel)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)

                    if let secondary = secondaryLabel, let action = secondaryAction {
                        Button(secondary, action: action)
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                            .tint(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
