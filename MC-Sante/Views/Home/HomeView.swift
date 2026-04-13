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

    // MARK: Section card helpers

    /// Inline legend dot + label for multi-series charts.
    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).foregroundStyle(.secondary)
        }
    }

    private var hasChartData: Bool { viewModel.recentSnapshots.count >= 2 }

    // MARK: Sommeil

    private var sleepSection: some View {
        let snap = viewModel.todaySnapshot
        return VStack(alignment: .leading, spacing: 14) {
            // Header + legend
            HStack {
                sectionHeader(L10n.sectionSleep, icon: "moon.fill")
                Spacer()
                HStack(spacing: 10) {
                    legendDot(.indigo, "REM")
                    legendDot(.blue,   L10n.deepSleep)
                    legendDot(.teal,   L10n.lightSleep)
                }
                .font(.caption2)
            }

            // Combined 7-day stacked chart
            if hasChartData {
                SleepChartView(snapshots: viewModel.recentSnapshots, selectedDate: viewModel.selectedDate)
                    .frame(height: 150)
            }

            Divider()

            // Individual chips (2-column)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                MetricChip(
                    emoji: "😴", title: L10n.totalDuration,
                    value: snap?.sleepDurationHours.map { $0.hoursMinutesString } ?? "—",
                    accentColor: snap?.sleepDurationHours != nil ? .sleepColor : .secondary
                )
                MetricChip(
                    emoji: "🌙", title: L10n.remSleep,
                    value: snap?.sleepREMMinutes.map { $0.minutesFormatted } ?? "—",
                    accentColor: snap?.sleepREMMinutes != nil ? .indigo : .secondary
                )
                MetricChip(
                    emoji: "💤", title: L10n.deepSleep,
                    value: snap?.sleepDeepMinutes.map { $0.minutesFormatted } ?? "—",
                    accentColor: snap?.sleepDeepMinutes != nil ? .blue : .secondary
                )
                MetricChip(
                    emoji: "🛌", title: L10n.lightSleep,
                    value: snap?.sleepCoreMinutes.map { $0.minutesFormatted } ?? "—",
                    accentColor: snap?.sleepCoreMinutes != nil ? .teal : .secondary
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Cardiaque

    private var cardiacSection: some View {
        let snap = viewModel.todaySnapshot
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(L10n.sectionCardiac, icon: "heart.fill")
                Spacer()
                HStack(spacing: 10) {
                    legendDot(.heartColor, "HR")
                    legendDot(.pink,       "HRV")
                }
                .font(.caption2)
            }

            if hasChartData {
                CardiacChartView(snapshots: viewModel.recentSnapshots, selectedDate: viewModel.selectedDate)
                    .frame(height: 150)
            }

            Divider()

            HStack(spacing: 8) {
                MetricChip(
                    emoji: "❤️", title: L10n.restingHR,
                    value: snap?.restingHeartRate.map { "\(Int($0)) bpm" } ?? "—",
                    accentColor: snap?.restingHeartRate != nil ? .heartColor : .secondary
                )
                MetricChip(
                    emoji: "💓", title: "HRV",
                    value: snap?.hrvSDNN.map { "\(Int($0)) ms" } ?? "—",
                    accentColor: snap?.hrvSDNN != nil ? .pink : .secondary
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Activité

    private var activitySection: some View {
        let snap = viewModel.todaySnapshot
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionHeader(L10n.sectionActivity, icon: "figure.run")
                Spacer()
                HStack(spacing: 10) {
                    legendDot(.activityColor, L10n.activeCalories)
                    legendDot(.green,         L10n.exercise)
                }
                .font(.caption2)
            }

            if hasChartData {
                ActivityChartView(snapshots: viewModel.recentSnapshots, selectedDate: viewModel.selectedDate)
                    .frame(height: 130)
            }

            Divider()

            HStack(spacing: 8) {
                MetricChip(
                    emoji: "🔥", title: L10n.activeCalories,
                    value: snap?.activeCalories.map { "\(Int($0)) kcal" } ?? "—",
                    accentColor: snap?.activeCalories != nil ? .activityColor : .secondary
                )
                MetricChip(
                    emoji: "🏃", title: L10n.exercise,
                    value: snap?.exerciseMinutes.map { $0.minutesFormatted } ?? "—",
                    accentColor: snap?.exerciseMinutes != nil ? .green : .secondary
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Cycle

    private var cycleSection: some View {
        let hasCycleData = viewModel.recentSnapshots.contains { ($0.menstrualFlowRaw ?? 0) > 0 }
        return Group {
            if hasCycleData {
                let snap = viewModel.todaySnapshot
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeader(L10n.sectionCycle, icon: "drop.fill")

                    CycleChartView(snapshots: viewModel.recentSnapshots, selectedDate: viewModel.selectedDate)
                        .frame(height: 110)

                    Divider()

                    MetricChip(
                        emoji: "🩸", title: L10n.menstrualFlow,
                        value: snap?.menstrualFlowRaw.map { menstrualFlowLabel($0) } ?? "—",
                        accentColor: snap?.menstrualFlowRaw != nil ? .pink : .secondary
                    )
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
        let snap = viewModel.todaySnapshot
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(L10n.sectionEnvironment, icon: "cloud.sun.fill")

            if hasChartData {
                WeatherChartView(snapshots: viewModel.recentSnapshots, selectedDate: viewModel.selectedDate)
                    .frame(height: 130)
            }

            Divider()

            HStack(spacing: 8) {
                MetricChip(
                    emoji: "🌡️", title: L10n.temperature,
                    value: snap?.temperatureCelsius.map { "\($0.oneDecimal) °C" } ?? "—",
                    accentColor: snap?.temperatureCelsius != nil ? .weatherColor : .secondary
                )
                MetricChip(
                    emoji: "📊", title: L10n.pressure,
                    value: snap?.pressureHPa.map { "\(Int($0)) hPa" } ?? "—",
                    accentColor: snap?.pressureHPa != nil ? .cyan : .secondary
                )
                MetricChip(
                    emoji: "💧", title: L10n.humidity,
                    value: snap?.humidityPercent.map { "\(Int($0)) %" } ?? "—",
                    accentColor: snap?.humidityPercent != nil ? .blue : .secondary
                )
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Humeur

    private var moodSection: some View {
        let hasMoodData = viewModel.recentSnapshots.contains { $0.moodValence != nil }
        return Group {
            if hasMoodData {
                let snap = viewModel.todaySnapshot
                VStack(alignment: .leading, spacing: 14) {
                    sectionHeader(L10n.sectionMood, icon: "brain.head.profile")

                    MoodChartView(snapshots: viewModel.recentSnapshots, selectedDate: viewModel.selectedDate)
                        .frame(height: 130)

                    Divider()

                    MetricChip(
                        emoji: "🧠", title: L10n.valence,
                        value: snap?.moodValence.map { moodLabel($0) } ?? "—",
                        accentColor: snap?.moodValence != nil ? .moodColor : .secondary
                    )
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
