import Foundation
import SwiftData

@Observable
final class HomeViewModel {
    var todaySnapshot: DailySnapshot?
    var todayEntries: [DailyEntry] = []
    var isLoading = false

    // Sparkline: last 7 days of snapshots (oldest → newest)
    var recentSnapshots: [DailySnapshot] = []

    // Date navigation
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)

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

    @MainActor
    func loadDay(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        let day = selectedDate

        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == day }
        )
        let cached = (try? context.fetch(snapshotDescriptor))?.first

        if let cached, cached.isComplete {
            todaySnapshot = cached
        } else {
            await snapshotService.buildSnapshot(for: day, context: context)
            todaySnapshot = (try? context.fetch(snapshotDescriptor))?.first
        }

        let entryDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == day }
        )
        todayEntries = (try? context.fetch(entryDescriptor)) ?? []

        recentSnapshots = loadRecentSnapshots(before: day, context: context)

        if recentSnapshots.count < 7 {
            await backfillRecentDays(around: day, context: context)
            recentSnapshots = loadRecentSnapshots(before: day, context: context)
        }
    }

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

        recentSnapshots = loadRecentSnapshots(before: day, context: context)
    }

    private func backfillRecentDays(around day: Date, context: ModelContext) async {
        let calendar = Calendar.current
        for offset in -6...0 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: day) else { continue }
            let startOfDay = calendar.startOfDay(for: date)
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
}
