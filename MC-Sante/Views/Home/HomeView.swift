import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HomeViewModel
    @State private var logViewModel = LogViewModel()
    @State private var showingAddCategory = false
    @State private var safeAreaTop: CGFloat = 0

    // Per-section visibility (persisted in UserDefaults)
    @AppStorage("section_sleep")    private var showSleep    = true
    @AppStorage("section_cardiac")  private var showCardiac  = true
    @AppStorage("section_activity") private var showActivity = true
    @AppStorage("section_cycle")    private var showCycle    = true
    @AppStorage("section_weather")  private var showWeather  = true
    @AppStorage("section_mood")     private var showMood     = true

    var onSettingsTap: () -> Void = {}

    init(snapshotService: SnapshotService, onSettingsTap: @escaping () -> Void = {}) {
        _viewModel = State(wrappedValue: HomeViewModel(snapshotService: snapshotService))
        self.onSettingsTap = onSettingsTap
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Pushes content below status bar (height read from overlay)
                Color.clear.frame(height: safeAreaTop)

                // Header: title left, buttons right
                HStack(alignment: .center) {
                    Text(viewModel.selectedDate.dayMonthString)
                        .font(.largeTitle.weight(.bold))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        if !viewModel.isToday {
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedDate = Calendar.current.startOfDay(for: .now)
                                }
                            } label: {
                                Text(LocalizationManager.shared.language == .french ? "Aujourd'hui" : "Today")
                                    .font(.callout.weight(.medium))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.accentColor.opacity(0.12))
                                    .foregroundStyle(Color.accentColor)
                                    .clipShape(Capsule())
                            }
                            .transition(.opacity.combined(with: .scale))
                            .sensoryFeedback(.selection, trigger: viewModel.isToday)
                        }
                        Button {
                            onSettingsTap()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.title3)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isToday)

                // Calendar strip (scrolls with content)
                dateNavigator
                    .padding(.bottom, 12)

                Divider()

                if viewModel.isLoading && viewModel.todaySnapshot == nil {
                    skeletonContent
                } else {
                    dataContent
                }
            }
        }
        .refreshable {
            await viewModel.forceRefresh(context: modelContext)
        }
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) {
            GeometryReader { geo in
                let inset = geo.safeAreaInsets.top
                LinearGradient(
                    stops: [
                        .init(color: Color(.systemBackground), location: 0),
                        .init(color: Color(.systemBackground).opacity(0.85), location: 0.5),
                        .init(color: Color(.systemBackground).opacity(0), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: inset + 24)
                .ignoresSafeArea(edges: .top)
                .onAppear { safeAreaTop = inset }
            }
            .frame(height: 0)
        }
        .sheet(isPresented: $showingAddCategory) {
            CategoryEditorSheet(viewModel: logViewModel)
        }
        .task {
            logViewModel.configure(context: modelContext)
            await viewModel.loadDay(context: modelContext)
        }
        .onChange(of: viewModel.selectedDate) { _, newDate in
            logViewModel.selectedDate = newDate
            logViewModel.loadEntriesForCurrentDate()
            Task { await viewModel.loadDay(context: modelContext) }
        }
    }

    // MARK: Date navigator (infinite scroll strip)

    /// Number of past days available in the strip.
    private static let stripDayCount = 365

    /// All dates in the strip, from oldest (index 0) to today (last).
    private var stripDays: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        return (0..<Self.stripDayCount).reversed().compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }
    }

    private var dateNavigator: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(stripDays, id: \.self) { day in
                        let isSelected = Calendar.current.isDate(day, inSameDayAs: viewModel.selectedDate)
                        let isTodayDate = Calendar.current.isDateInToday(day)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedDate = Calendar.current.startOfDay(for: day)
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text(day.weekdayInitial)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(isSelected ? .primary : .secondary)

                                Text(day.dayNumberString)
                                    .font(.callout)
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .foregroundStyle(
                                        isSelected ? .white
                                        : isTodayDate ? Color.red
                                        : .primary
                                    )
                                    .frame(width: 32, height: 32)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? Color(.label) : .clear)
                                    )
                            }
                            .frame(width: 48)
                        }
                        .buttonStyle(.plain)
                        .sensoryFeedback(.selection, trigger: isSelected)
                        .id(day)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                proxy.scrollTo(viewModel.selectedDate, anchor: .trailing)
            }
            .onChange(of: viewModel.selectedDate) { _, newDate in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
        }
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

            logSection
            if showSleep    { sleepSection }
            if showCardiac  { cardiacSection }
            if showActivity { activitySection }
            if showCycle    { cycleSection }
            if showWeather  { weatherSection }
            if showMood     { moodSection }
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

    private var snapshots: [DailySnapshot] { viewModel.recentSnapshots }

    private var hasSleepChartData: Bool {
        snapshots.filter { $0.sleepDurationHours != nil }.count >= 2
    }
    private var hasCardiacChartData: Bool {
        snapshots.filter { $0.restingHeartRate != nil || $0.hrvSDNN != nil }.count >= 2
    }
    private var hasActivityChartData: Bool {
        snapshots.filter { $0.activeCalories != nil || $0.exerciseMinutes != nil }.count >= 2
    }
    private var hasCycleChartData: Bool {
        snapshots.filter { $0.menstrualFlowRaw != nil }.count >= 2
    }
    private var hasWeatherChartData: Bool {
        snapshots.filter { $0.temperatureCelsius != nil }.count >= 2
    }
    private var hasMoodChartData: Bool {
        snapshots.filter { $0.moodValence != nil }.count >= 2
    }

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
            if hasSleepChartData {
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

            if hasCardiacChartData {
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

            if hasActivityChartData {
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
        let snap = viewModel.todaySnapshot
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(L10n.sectionCycle, icon: "drop.fill")

            if hasCycleChartData {
                CycleChartView(snapshots: viewModel.recentSnapshots, selectedDate: viewModel.selectedDate)
                    .frame(height: 110)
            }

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

            if hasWeatherChartData {
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
        let snap = viewModel.todaySnapshot
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(L10n.sectionMood, icon: "brain.head.profile")

            if hasMoodChartData {
                MoodChartView(snapshots: viewModel.recentSnapshots, selectedDate: viewModel.selectedDate)
                    .frame(height: 130)
            }

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

    // MARK: Log section

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(L10n.logTitle, icon: "pencil.circle.fill")

            if logViewModel.categories.isEmpty {
                Text(LocalizationManager.shared.language == .french
                     ? "Aucune catégorie active."
                     : "No active categories.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(logViewModel.categories) { category in
                    CategoryRow(
                        category: category,
                        value: Binding(
                            get: { logViewModel.currentValue(for: category) },
                            set: { logViewModel.setValue($0, for: category) }
                        )
                    )
                }
            }

            Button {
                showingAddCategory = true
            } label: {
                Label(L10n.addCategory, systemImage: "plus.circle")
                    .font(.callout)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            DayNoteField(text: Binding(
                get: { logViewModel.entriesForDate.values.first(where: { $0.note != nil })?.note ?? "" },
                set: { logViewModel.setDayNote($0) }
            ))
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
