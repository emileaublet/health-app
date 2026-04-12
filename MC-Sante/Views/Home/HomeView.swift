import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel
    @State private var showingCelebration = false

    init(snapshotService: SnapshotService) {
        _viewModel = State(wrappedValue: HomeViewModel(snapshotService: snapshotService))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20, pinnedViews: []) {
                    // Streak banner
                    if viewModel.currentStreak > 0 {
                        streakBanner
                    }

                    // Sommeil
                    sleepSection

                    // Cardiaque
                    cardiacSection

                    // Activité
                    activitySection

                    // Météo
                    weatherSection

                    // Humeur
                    moodSection

                    // Insight du jour
                    insightSection

                    // Disclaimer
                    disclaimerFooter
                }
                .padding()
            }
            .navigationTitle("Aujourd'hui")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.loadToday(context: modelContext) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await viewModel.loadToday(context: modelContext)
            }
        }
        .task {
            await viewModel.loadToday(context: modelContext)
        }
    }

    // MARK: Streak banner

    private var streakBanner: some View {
        HStack {
            Text("🔥 \(viewModel.currentStreak) jour\(viewModel.currentStreak > 1 ? "s" : "") de suite")
                .font(.callout.weight(.semibold))
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: Sommeil

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Sommeil", icon: "moon.fill")

            let snap = viewModel.todaySnapshot
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let hours = snap?.sleepDurationHours {
                    MetricCard(
                        emoji: "😴",
                        title: "Durée totale",
                        value: hours.hoursMinutesString,
                        subtitle: nil,
                        accentColor: .sleepColor,
                        progress: min(hours / 9.0, 1.0)
                    )
                } else {
                    MetricCardMissing(emoji: "😴", title: "Durée totale")
                }

                if let rem = snap?.sleepREMMinutes {
                    MetricCard(
                        emoji: "🌙",
                        title: "Sommeil REM",
                        value: "\(Int(rem)) min",
                        subtitle: nil,
                        accentColor: .indigo
                    )
                } else {
                    MetricCardMissing(emoji: "🌙", title: "Sommeil REM")
                }

                if let deep = snap?.sleepDeepMinutes {
                    MetricCard(
                        emoji: "💤",
                        title: "Sommeil profond",
                        value: "\(Int(deep)) min",
                        subtitle: nil,
                        accentColor: .blue
                    )
                } else {
                    MetricCardMissing(emoji: "💤", title: "Sommeil profond")
                }

                if let core = snap?.sleepCoreMinutes {
                    MetricCard(
                        emoji: "🛌",
                        title: "Sommeil léger",
                        value: "\(Int(core)) min",
                        subtitle: nil,
                        accentColor: .teal
                    )
                } else {
                    MetricCardMissing(emoji: "🛌", title: "Sommeil léger")
                }
            }
        }
    }

    // MARK: Cardiaque

    private var cardiacSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Cardiaque", icon: "heart.fill")

            let snap = viewModel.todaySnapshot
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let bpm = snap?.restingHeartRate {
                    MetricCard(
                        emoji: "❤️",
                        title: "FC repos",
                        value: "\(Int(bpm)) bpm",
                        subtitle: nil,
                        accentColor: .heartColor
                    )
                } else {
                    MetricCardMissing(emoji: "❤️", title: "FC repos")
                }

                if let hrv = snap?.hrvSDNN {
                    MetricCard(
                        emoji: "💓",
                        title: "HRV",
                        value: "\(Int(hrv)) ms",
                        subtitle: nil,
                        accentColor: .pink
                    )
                } else {
                    MetricCardMissing(emoji: "💓", title: "HRV")
                }
            }
        }
    }

    // MARK: Activité

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Activité", icon: "figure.run")

            let snap = viewModel.todaySnapshot
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let cal = snap?.activeCalories {
                    MetricCard(
                        emoji: "🔥",
                        title: "Calories actives",
                        value: "\(Int(cal)) kcal",
                        subtitle: nil,
                        accentColor: .activityColor,
                        progress: min(cal / 500.0, 1.0)
                    )
                } else {
                    MetricCardMissing(emoji: "🔥", title: "Calories actives")
                }

                if let min = snap?.exerciseMinutes {
                    MetricCard(
                        emoji: "🏃",
                        title: "Exercice",
                        value: "\(Int(min)) min",
                        subtitle: nil,
                        accentColor: .green,
                        progress: min / 60.0
                    )
                } else {
                    MetricCardMissing(emoji: "🏃", title: "Exercice")
                }
            }
        }
    }

    // MARK: Météo

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Environnement", icon: "cloud.sun.fill")

            let snap = viewModel.todaySnapshot
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let temp = snap?.temperatureCelsius {
                    MetricCard(
                        emoji: "🌡️",
                        title: "Température",
                        value: "\(temp.oneDecimal) °C",
                        subtitle: nil,
                        accentColor: .weatherColor
                    )
                } else {
                    MetricCardMissing(emoji: "🌡️", title: "Température")
                }

                if let pressure = snap?.pressureHPa {
                    MetricCard(
                        emoji: "📊",
                        title: "Pression",
                        value: "\(Int(pressure)) hPa",
                        subtitle: nil,
                        accentColor: .cyan
                    )
                } else {
                    MetricCardMissing(emoji: "📊", title: "Pression")
                }

                if let humidity = snap?.humidityPercent {
                    MetricCard(
                        emoji: "💧",
                        title: "Humidité",
                        value: "\(Int(humidity)) %",
                        subtitle: nil,
                        accentColor: .blue
                    )
                } else {
                    MetricCardMissing(emoji: "💧", title: "Humidité")
                }
            }
        }
    }

    // MARK: Humeur

    private var moodSection: some View {
        Group {
            if let valence = viewModel.todaySnapshot?.moodValence {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader("Humeur", icon: "brain.head.profile")
                    MetricCard(
                        emoji: "🧠",
                        title: "Valence",
                        value: moodLabel(valence),
                        subtitle: String(format: "Score : %+.2f", valence),
                        accentColor: .moodColor,
                        progress: (valence + 1.0) / 2.0
                    )
                }
            }
        }
    }

    // MARK: Insight

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("Corrélation du jour", icon: "sparkles")

            if let insight = viewModel.topInsight {
                InsightCard(insight: insight)
            } else if viewModel.daysUntilFirstInsight > 0 {
                noInsightPlaceholder
            }
        }
    }

    private var noInsightPlaceholder: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.title2)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Continue à logger tes données")
                    .font(.callout.weight(.medium))
                Text("Encore \(viewModel.daysUntilFirstInsight) jour\(viewModel.daysUntilFirstInsight > 1 ? "s" : "") pour les premières corrélations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Disclaimer

    private var disclaimerFooter: some View {
        Text("⚠️ Ces données sont indicatives. Elles ne remplacent pas un avis médical professionnel.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }

    // MARK: Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }

    private func moodLabel(_ valence: Double) -> String {
        switch valence {
        case 0.6...:   return "Très positif"
        case 0.2...:   return "Positif"
        case -0.2...:  return "Neutre"
        case -0.6...:  return "Négatif"
        default:       return "Très négatif"
        }
    }
}
