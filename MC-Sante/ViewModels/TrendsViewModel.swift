import Foundation
import SwiftData

@Observable
final class TrendsViewModel {
    var correlations: [CorrelationResult] = []
    var selectedWindow: Int = 14   // 7, 14, ou 30 jours
    var isComputing = false
    var hasSufficientData = false
    var daysUntilReady: Int = 0
    var hasNewCorrelation = false

    private(set) var cachedSeries: [MetricSeries] = []

    // MARK: Compute

    @MainActor
    func recompute(context: ModelContext) async {
        isComputing = true
        defer { isComputing = false }

        // Charger les données brutes
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let snapshots = (try? context.fetch(snapshotDescriptor)) ?? []

        let entryDescriptor = FetchDescriptor<DailyEntry>()
        let entries = (try? context.fetch(entryDescriptor)) ?? []

        let categoryDescriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == true }
        )
        let categories = (try? context.fetch(categoryDescriptor)) ?? []

        // Vérifier si assez de données
        let count = snapshots.count
        daysUntilReady = max(0, 7 - count)
        hasSufficientData = count >= 7

        guard hasSufficientData else {
            correlations = []
            return
        }

        // Calculer en arrière-plan
        let series = CorrelationEngine.extractAllSeries(
            snapshots: snapshots,
            entries: entries,
            categories: categories
        )
        cachedSeries = series
        let results = CorrelationEngine.computeAll(
            series: series,
            windowDays: selectedWindow,
            maxLag: 1
        )

        // Sauvegarder les nouveaux résultats
        let existingDescriptor = FetchDescriptor<CorrelationResult>()
        let existing = (try? context.fetch(existingDescriptor)) ?? []
        for old in existing { context.delete(old) }
        for result in results { context.insert(result) }
        try? context.save()

        let previousCount = correlations.count
        correlations = results
        if results.count > previousCount {
            hasNewCorrelation = true
        }
    }

    func clearNewBadge() {
        hasNewCorrelation = false
    }

    // MARK: Filtered by window

    var filteredCorrelations: [CorrelationResult] {
        correlations.filter { $0.windowDays == selectedWindow }
    }

    // MARK: Series for chart

    func seriesFor(result: CorrelationResult) -> (a: [(Date, Double)], b: [(Date, Double)])? {
        guard
            let seriesA = cachedSeries.first(where: { $0.name == result.metricA }),
            let seriesB = cachedSeries.first(where: { $0.name == result.metricB })
        else { return nil }

        let cal = Calendar.current
        let cutoffBase = cal.date(byAdding: .day, value: -selectedWindow, to: .now) ?? .now
        let cutoff = cal.startOfDay(for: cutoffBase)

        let a = seriesA.values.filter { $0.key >= cutoff }.map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }
        let b = seriesB.values.filter { $0.key >= cutoff }.map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }

        return (a, b)
    }
}
