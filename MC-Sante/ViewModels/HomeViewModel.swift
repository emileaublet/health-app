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

    // CalendarStrip: dates that have snapshot data
    var datesWithData: Set<Date> = []

    // Streak logging
    var currentStreak: Int = 0

    // Error handling
    var showSaveError: Bool = false

    private let snapshotService: SnapshotService

    init(snapshotService: SnapshotService) {
        self.snapshotService = snapshotService
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    /// Unified data loader. When `forceRefresh` is true, always fetches from HealthKit/weather.
    @MainActor
    func loadDay(context: ModelContext, forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        let day = selectedDate

        // Snapshot: use cache or fetch fresh
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == day }
        )

        if forceRefresh {
            await snapshotService.buildSnapshot(for: day, context: context)
            todaySnapshot = (try? context.fetch(snapshotDescriptor))?.first
        } else {
            let cached = (try? context.fetch(snapshotDescriptor))?.first
            if let cached, cached.isComplete {
                todaySnapshot = cached
            } else {
                await snapshotService.buildSnapshot(for: day, context: context)
                todaySnapshot = (try? context.fetch(snapshotDescriptor))?.first
            }
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
        if !forceRefresh && recentSnapshots.count < 7 {
            await backfillRecentDays(around: day, context: context)
            recentSnapshots = loadRecentSnapshots(before: day, context: context)
        }

        // Streak
        currentStreak = computeStreak(context: context)

        // CalendarStrip: load all dates that have snapshot data
        loadDatesWithData(context: context)
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
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        // Only look back 90 days max to avoid fetching entire history
        guard let cutoff = calendar.date(byAdding: .day, value: -90, to: today) else { return 0 }
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date >= cutoff },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let snapshots = (try? context.fetch(descriptor)) ?? []
        var streak = 0
        var currentDate = today
        for snapshot in snapshots {
            if snapshot.date == currentDate {
                streak += 1
                guard let prev = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = prev
            } else {
                break
            }
        }
        return streak
    }

    private func loadDatesWithData(context: ModelContext) {
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.isComplete == true }
        )
        let snapshots = (try? context.fetch(descriptor)) ?? []
        datesWithData = Set(snapshots.map { $0.date })
    }
}
