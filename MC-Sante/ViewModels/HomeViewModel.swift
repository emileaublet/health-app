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

    // Streak logging
    var currentStreak: Int = 0

    private let snapshotService: SnapshotService

    init(snapshotService: SnapshotService) {
        self.snapshotService = snapshotService
    }

    @MainActor
    func loadToday(context: ModelContext) async {
        isLoading = true
        defer { isLoading = false }

        // Construire/rafraîchir le snapshot du jour
        await snapshotService.buildSnapshot(for: .now, context: context)

        // Recharger depuis SwiftData
        let today = Calendar.current.startOfDay(for: .now)
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == today }
        )
        todaySnapshot = (try? context.fetch(snapshotDescriptor))?.first

        // Entrées manuelles du jour
        let entryDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == today }
        )
        todayEntries = (try? context.fetch(entryDescriptor)) ?? []

        // Top insight
        let correlationDescriptor = FetchDescriptor<CorrelationResult>(
            sortBy: [SortDescriptor(\.pearsonR, order: .reverse)]
        )
        let correlations = (try? context.fetch(correlationDescriptor)) ?? []
        topInsight = correlations.max(by: { abs($0.pearsonR) < abs($1.pearsonR) })

        // Jours jusqu'au premier insight (besoin de 7 entrées)
        let snapshotsAll = FetchDescriptor<DailySnapshot>()
        let count = (try? context.fetchCount(snapshotsAll)) ?? 0
        daysUntilFirstInsight = max(0, 7 - count)

        // Streak
        currentStreak = computeStreak(context: context)
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
