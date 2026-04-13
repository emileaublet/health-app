import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    // Données affichées
    var todaySnapshot: DailySnapshot?
    var todayEntries: [DailyEntry] = []
    var topInsight: CorrelationResult?
    var daysUntilFirstInsight: Int = 0
    var isLoading = false

    // Sparkline: last 7 days of snapshots (oldest → newest)
    var recentSnapshots: [DailySnapshot] = []

    // Date navigation
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)

    // Streak logging
    var currentStreak: Int = 0

    private let snapshotService: SnapshotService

    init(snapshotService: SnapshotService) {
        self.snapshotService = snapshotService
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var canGoForward: Bool {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return false }
        return tomorrow <= Calendar.current.startOfDay(for: .now)
    }

    func goToPreviousDay() {
        guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        todaySnapshot = nil
        selectedDate = prev
    }

    func goToNextDay() {
        guard canGoForward,
              let next = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        todaySnapshot = nil
        selectedDate = next
    }

    var dateTitle: String {
        if isToday { return L10n.today }
        if Calendar.current.isDateInYesterday(selectedDate) { return L10n.yesterday }
        return selectedDate.dayOfWeekString
    }

    @MainActor
    func loadDay(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        let day = selectedDate

        // Check if we already have a complete snapshot cached in SwiftData
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == day }
        )
        let cached = (try? context.fetch(snapshotDescriptor))?.first

        if let cached, cached.isComplete {
            // Complete snapshot exists — use cache, no network calls
            todaySnapshot = cached
        } else {
            // No snapshot or incomplete — fetch fresh data
            await snapshotService.buildSnapshot(for: day, context: context)
            todaySnapshot = (try? context.fetch(snapshotDescriptor))?.first
        }

        // Manual entries for the day
        let entryDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == day }
        )
        todayEntries = (try? context.fetch(entryDescriptor)) ?? []

        // Top insight
        let correlationDescriptor = FetchDescriptor<CorrelationResult>(
            sortBy: [SortDescriptor(\.pearsonR, order: .reverse)]
        )
        let correlations = (try? context.fetch(correlationDescriptor)) ?? []
        topInsight = correlations.max(by: { abs($0.pearsonR) < abs($1.pearsonR) })

        // Days until first insight
        let snapshotsAll = FetchDescriptor<DailySnapshot>()
        let count = (try? context.fetchCount(snapshotsAll)) ?? 0
        daysUntilFirstInsight = max(0, 7 - count)

        // Sparkline data (last 7 days ending on selectedDate)
        recentSnapshots = loadRecentSnapshots(before: day, context: context)

        // Backfill missing days from HealthKit for bar charts
        if recentSnapshots.count < 7 {
            await backfillRecentDays(around: day, context: context)
            recentSnapshots = loadRecentSnapshots(before: day, context: context)
        }

        // Streak
        currentStreak = computeStreak(context: context)
    }

    /// Force-refresh: always fetches from HealthKit/weather, ignoring cache.
    @MainActor
    func forceRefresh(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        let day = selectedDate
        await snapshotService.buildSnapshot(for: day, context: context)

        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == day }
        )
        todaySnapshot = (try? context.fetch(snapshotDescriptor))?.first

        let entryDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == day }
        )
        todayEntries = (try? context.fetch(entryDescriptor)) ?? []

        let correlationDescriptor = FetchDescriptor<CorrelationResult>(
            sortBy: [SortDescriptor(\.pearsonR, order: .reverse)]
        )
        let correlations = (try? context.fetch(correlationDescriptor)) ?? []
        topInsight = correlations.max(by: { abs($0.pearsonR) < abs($1.pearsonR) })

        let snapshotsAll = FetchDescriptor<DailySnapshot>()
        let count = (try? context.fetchCount(snapshotsAll)) ?? 0
        daysUntilFirstInsight = max(0, 7 - count)

        // Sparkline data
        recentSnapshots = loadRecentSnapshots(before: day, context: context)

        currentStreak = computeStreak(context: context)
    }

    /// Builds snapshots from HealthKit for missing days in the last 7 days.
    private func backfillRecentDays(around day: Date, context: ModelContext) async {
        let calendar = Calendar.current
        for offset in -6...0 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: day) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
            // Only build if we don't have today or a future date
            guard startOfDay <= calendar.startOfDay(for: .now) else { continue }
            let descriptor = FetchDescriptor<DailySnapshot>(
                predicate: #Predicate { $0.date == startOfDay }
            )
            let exists = ((try? context.fetch(descriptor))?.first?.isComplete) ?? false
            if !exists {
                await snapshotService.buildSnapshot(for: startOfDay, context: context)
            }
        }
    }

    private func loadRecentSnapshots(before day: Date, context: ModelContext) -> [DailySnapshot] {
        guard let weekAgo = Calendar.current.date(byAdding: .day, value: -6, to: day) else { return [] }
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date >= weekAgo && $0.date <= day },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private func computeStreak(context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let snapshots = (try? context.fetch(descriptor)) ?? []
        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: .now)
        for snapshot in snapshots {
            if snapshot.date == currentDate {
                streak += 1
                guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = prev
            } else {
                break
            }
        }
        return streak
    }
}
