import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel
    @State private var showingCelebration = false
    @Binding var selectedTab: ContentView.Tab

    init(snapshotService: SnapshotService, selectedTab: Binding<ContentView.Tab>) {
        _viewModel = State(wrappedValue: HomeViewModel(snapshotService: snapshotService))
        _selectedTab = selectedTab
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateNavigator
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))

                Divider()

                ScrollView {
                    if viewModel.isLoading && viewModel.todaySnapshot == nil {
                        skeletonContent
                    } else {
                        dataContent
                    }
                }
                .refreshable {
                    await viewModel.forceRefresh(context: modelContext)
                }
            }
            .navigationTitle(L10n.tabHome)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            selectedTab = .log
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                        }
                        Button {
                            Task { await viewModel.forceRefresh(context: modelContext) }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadDay(context: modelContext)
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            Task { await viewModel.loadDay(context: modelContext) }
        }
    }

    // MARK: Date navigator

    private var dateNavigator: some View {
        HStack {
            Button {
                viewModel.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Button {
                viewModel.selectedDate = Calendar.current.startOfDay(for: .now)
            } label: {
                VStack(spacing: 2) {
                    Text(viewModel.dateTitle)
                        .font(.headline)
                    Text(viewModel.selectedDate.shortDateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(LocalizationManager.shared.language == .french ? "↩ Aujourd'hui" : "↩ Today")
                        .font(.caption2)
                        .foregroundStyle(.accentColor)
                        .opacity(viewModel.isToday ? 0 : 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isToday)

            Spacer()

            Button {
                viewModel.goToNextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .opacity(viewModel.canGoForward ? 1 : 0.3)
            .disabled(!viewModel.canGoForward)
        }
    }

    // MARK: Streak banner

    private var streakBanner: some View {
        HStack {
            Text(L10n.streakDays(viewModel.currentStreak))
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "flame.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .orange.opacity(0.3), radius: 6, y: 3)
    }

    // MARK: Skeleton

    private var skeletonContent: some View {
        LazyVStack(spacing: 20, pinnedViews: []) {
            SkeletonSection(icon: "moon.fill", cardCount: 4, columns: 2)
            SkeletonSection(icon: "heart.fill", cardCount: 2, columns: 2)
            SkeletonSection(icon: "figure.run", cardCount: 2, columns: 2)
            SkeletonSection(icon: "cloud.sun.fill", cardCount: 3, columns: 3)
        }
        .padding()
    }

    // MARK: Data content

    private var dataContent: some View {
        LazyVStack(spacing: 20, pinnedViews: []) {
            // Streak banner
            if viewModel.currentStreak > 0 {
                streakBanner
            }

            // Empty state: no snapshot and not loading
            if viewModel.todaySnapshot == nil && !viewModel.isLoading {
                VStack(spacing: 12) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(LocalizationManager.shared.language == .french
                         ? "Aucune donnée HealthKit pour ce jour."
                         : "No HealthKit data for this day.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }

            sleepSection
            cardiacSection
            activitySection
            cycleSection
            weatherSection
            moodSection
            insightSection
            disclaimerFooter
        }
        .padding()
    }

    // MARK: Bar chart helpers

    private func barData(_ keyPath: KeyPath<DailySnapshot, Double?>) -> [Double] {
        viewModel.recentSnapshots.map { $0[keyPath: keyPath] ?? 0 }
    }

    /// Index of the selected day within recentSnapshots (for highlight)
    private var currentDayBarIndex: Int? {
        let day = viewModel.selectedDate
        return viewModel.recentSnapshots.firstIndex { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    // MARK: Sommeil

    private var sleepSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.sectionSleep, icon: "moon.fill")

            let snap = viewModel.todaySnapshot
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let hours = snap?.sleepDurationHours {
                    MetricCard(
                        emoji: "😴",
                        title: L10n.totalDuration,
                        value: hours.hoursMinutesString,
                        subtitle: nil,
                        accentColor: .sleepColor,
                        sparklineData: barData(\.sleepDurationHours),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "😴", title: L10n.totalDuration)
                }

                if let rem = snap?.sleepREMMinutes {
                    MetricCard(
                        emoji: "🌙",
                        title: L10n.remSleep,
                        value: rem.minutesFormatted,
                        subtitle: nil,
                        accentColor: .indigo,
                        sparklineData: barData(\.sleepREMMinutes),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "🌙", title: L10n.remSleep)
                }

                if let deep = snap?.sleepDeepMinutes {
                    MetricCard(
                        emoji: "💤",
                        title: L10n.deepSleep,
                        value: deep.minutesFormatted,
                        subtitle: nil,
                        accentColor: .blue,
                        sparklineData: barData(\.sleepDeepMinutes),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "💤", title: L10n.deepSleep)
                }

                if let core = snap?.sleepCoreMinutes {
                    MetricCard(
                        emoji: "🛌",
                        title: L10n.lightSleep,
                        value: core.minutesFormatted,
                        subtitle: nil,
                        accentColor: .teal,
                        sparklineData: barData(\.sleepCoreMinutes),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "🛌", title: L10n.lightSleep)
                }
            }
        }
    }

    // MARK: Cardiaque

    private var cardiacSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.sectionCardiac, icon: "heart.fill")

            let snap = viewModel.todaySnapshot
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let bpm = snap?.restingHeartRate {
                    MetricCard(
                        emoji: "❤️",
                        title: L10n.restingHR,
                        value: "\(Int(bpm)) bpm",
                        subtitle: nil,
                        accentColor: .heartColor,
                        sparklineData: barData(\.restingHeartRate),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "❤️", title: L10n.restingHR)
                }

                if let hrv = snap?.hrvSDNN {
                    MetricCard(
                        emoji: "💓",
                        title: "HRV",
                        value: "\(Int(hrv)) ms",
                        subtitle: nil,
                        accentColor: .pink,
                        sparklineData: barData(\.hrvSDNN),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "💓", title: "HRV")
                }
            }
        }
    }

    // MARK: Activite

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.sectionActivity, icon: "figure.run")

            let snap = viewModel.todaySnapshot
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let cal = snap?.activeCalories {
                    MetricCard(
                        emoji: "🔥",
                        title: L10n.activeCalories,
                        value: "\(Int(cal)) kcal",
                        subtitle: nil,
                        accentColor: .activityColor,
                        sparklineData: barData(\.activeCalories),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "🔥", title: L10n.activeCalories)
                }

                if let exerciseMins = snap?.exerciseMinutes {
                    MetricCard(
                        emoji: "🏃",
                        title: L10n.exercise,
                        value: exerciseMins.minutesFormatted,
                        subtitle: nil,
                        accentColor: .green,
                        sparklineData: barData(\.exerciseMinutes),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "🏃", title: L10n.exercise)
                }
            }
        }
    }

    // MARK: Cycle

    private var cycleSection: some View {
        Group {
            if let flow = viewModel.todaySnapshot?.menstrualFlowRaw {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(L10n.sectionCycle, icon: "drop.fill")
                    MetricCard(
                        emoji: "🩸",
                        title: L10n.menstrualFlow,
                        value: menstrualFlowLabel(flow),
                        subtitle: nil,
                        accentColor: .pink,
                        sparklineData: barData(\.menstrualFlowValue),
                        highlightIndex: currentDayBarIndex
                    )
                }
            }
        }
    }

    private func menstrualFlowLabel(_ rawValue: Int) -> String {
        switch rawValue {
        case 0: return L10n.flowNone
        case 1: return L10n.flowUnspecified
        case 2: return L10n.flowLight
        case 3: return L10n.flowMedium
        case 4: return L10n.flowHeavy
        default: return "—"
        }
    }

    // MARK: Météo

    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.sectionEnvironment, icon: "cloud.sun.fill")

            let snap = viewModel.todaySnapshot
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                if let temp = snap?.temperatureCelsius {
                    MetricCard(
                        emoji: "🌡️",
                        title: L10n.temperature,
                        value: "\(temp.oneDecimal) °C",
                        subtitle: nil,
                        accentColor: .weatherColor,
                        sparklineData: barData(\.temperatureCelsius),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "🌡️", title: L10n.temperature)
                }

                if let pressure = snap?.pressureHPa {
                    MetricCard(
                        emoji: "📊",
                        title: L10n.pressure,
                        value: "\(Int(pressure)) hPa",
                        subtitle: nil,
                        accentColor: .cyan,
                        sparklineData: barData(\.pressureHPa),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "📊", title: L10n.pressure)
                }

                if let humidity = snap?.humidityPercent {
                    MetricCard(
                        emoji: "💧",
                        title: L10n.humidity,
                        value: "\(Int(humidity)) %",
                        subtitle: nil,
                        accentColor: .blue,
                        sparklineData: barData(\.humidityPercent),
                        highlightIndex: currentDayBarIndex
                    )
                } else {
                    MetricCardMissing(emoji: "💧", title: L10n.humidity)
                }
            }
        }
    }

    // MARK: Humeur

    private var moodSection: some View {
        Group {
            if let valence = viewModel.todaySnapshot?.moodValence {
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(L10n.sectionMood, icon: "brain.head.profile")
                    MetricCard(
                        emoji: "🧠",
                        title: L10n.valence,
                        value: moodLabel(valence),
                        subtitle: L10n.scoreLabel(valence),
                        accentColor: .moodColor,
                        sparklineData: barData(\.moodValence),
                        highlightIndex: currentDayBarIndex
                    )
                }
            }
        }
    }

    // MARK: Insight

    private var insightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(L10n.sectionDailyCorrelation, icon: "sparkles")

            if let insight = viewModel.topInsight {
                InsightCard(insight: insight)
            } else if viewModel.daysUntilFirstInsight > 0 {
                noInsightPlaceholder
            }
        }
    }

    private var noInsightPlaceholder: some View {
        HStack(spacing: 0) {
            // Left accent bar
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 4)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 14, bottomLeadingRadius: 14,
                        bottomTrailingRadius: 0, topTrailingRadius: 0
                    )
                )

            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.keepLogging)
                        .font(.callout.weight(.medium))
                    Text(L10n.daysUntilCorrelations(viewModel.daysUntilFirstInsight))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ProgressView(
                        value: Double(7 - viewModel.daysUntilFirstInsight),
                        total: 7
                    )
                    .tint(.accentColor)
                }
                Spacer()
            }
            .padding()
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Disclaimer

    private var disclaimerFooter: some View {
        Text(L10n.disclaimerHome)
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.bottom, 8)
    }

    // MARK: Helpers

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(accentForSection(icon: icon))
                .frame(width: 8, height: 8)
            Label(title, systemImage: icon)
                .font(.title3.weight(.semibold))
        }
    }

    private func accentForSection(icon: String) -> Color {
        switch icon {
        case "moon.fill":           return .sleepColor
        case "heart.fill":          return .heartColor
        case "figure.run":          return .activityColor
        case "drop.fill":           return .pink
        case "cloud.sun.fill":      return .weatherColor
        case "brain.head.profile":  return .moodColor
        default:                    return .accentColor
        }
    }

    private func moodLabel(_ valence: Double) -> String {
        if valence >= 0.6 { return L10n.moodVeryPositive }
        if valence >= 0.2 { return L10n.moodPositive }
        if valence >= -0.2 { return L10n.moodNeutral }
        if valence >= -0.6 { return L10n.moodNegative }
        return L10n.moodVeryNegative
    }
}
