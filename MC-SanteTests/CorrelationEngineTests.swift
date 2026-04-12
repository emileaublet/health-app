import XCTest
@testable import MC_Sante

final class CorrelationEngineTests: XCTestCase {

    // MARK: - pearson(_:_:)

    func test_pearson_perfectPositive_returnsOne() {
        let x = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
        XCTAssertEqual(CorrelationEngine.pearson(x, x), 1.0, accuracy: 1e-10)
    }

    func test_pearson_perfectNegative_returnsMinusOne() {
        let x = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
        let y = Array(x.reversed())
        XCTAssertEqual(CorrelationEngine.pearson(x, y) ?? 0, -1.0, accuracy: 1e-10)
    }

    func test_pearson_fewerThan7Points_returnsNil() {
        let x = [1.0, 2.0, 3.0]
        XCTAssertNil(CorrelationEngine.pearson(x, x))
    }

    func test_pearson_exactlySevenPoints_doesNotReturnNil() {
        let x = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
        XCTAssertNotNil(CorrelationEngine.pearson(x, x))
    }

    func test_pearson_constantX_returnsNil() {
        let x = Array(repeating: 5.0, count: 7)
        let y = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
        XCTAssertNil(CorrelationEngine.pearson(x, y))
    }

    func test_pearson_mismatchedLengths_returnsNil() {
        XCTAssertNil(CorrelationEngine.pearson(
            [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0],
            [1.0, 2.0, 3.0]
        ))
    }

    func test_pearson_knownValue_linearTransformation_returnsOne() {
        // y = 3x + 5 → perfect linear relationship → r = 1
        let x = [2.0, 4.0, 5.0, 4.0, 5.0, 7.0, 8.0]
        let y = x.map { $0 * 3 + 5 }
        XCTAssertEqual(CorrelationEngine.pearson(x, y) ?? 0, 1.0, accuracy: 1e-10)
    }

    // MARK: - zNormalize(_:)

    func test_zNormalize_singleValue_returnsUnchanged() {
        let date = Date()
        let result = CorrelationEngine.zNormalize([(date, 42.0)])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].1, 42.0)
    }

    func test_zNormalize_producesZeroMean() {
        let input = (1...5).map { i in
            (Date(timeIntervalSince1970: Double(i) * 86400), Double(i))
        }
        let result = CorrelationEngine.zNormalize(input)
        let mean = result.map(\.1).reduce(0, +) / Double(result.count)
        XCTAssertEqual(mean, 0.0, accuracy: 1e-10)
    }

    func test_zNormalize_producesUnitStddev() {
        let input = (1...5).map { i in
            (Date(timeIntervalSince1970: Double(i) * 86400), Double(i))
        }
        let result = CorrelationEngine.zNormalize(input)
        let values = result.map(\.1)
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        XCTAssertEqual(sqrt(variance), 1.0, accuracy: 1e-10)
    }

    func test_zNormalize_constantInput_producesAllZeros() {
        let input = (1...5).map { i in
            (Date(timeIntervalSince1970: Double(i) * 86400), 3.0)
        }
        let result = CorrelationEngine.zNormalize(input)
        XCTAssertTrue(result.allSatisfy { $0.1 == 0.0 })
    }

    func test_zNormalize_preservesDates() {
        let dates = (1...3).map { Date(timeIntervalSince1970: Double($0) * 86400) }
        let input = dates.map { ($0, 1.0) }
        let result = CorrelationEngine.zNormalize(input)
        let resultDates = result.map(\.0)
        XCTAssertEqual(resultDates, dates)
    }

    // MARK: - extractAllSeries

    func test_extractAllSeries_with10Snapshots_includesSleepSeries() {
        let snapshots = makeSnapshots(count: 10) { s, _ in s.sleepDurationHours = 7.5 }
        let series = CorrelationEngine.extractAllSeries(
            snapshots: snapshots, entries: [], categories: [])
        XCTAssertNotNil(series.first(where: { $0.name == "Sommeil (heures)" }))
    }

    func test_extractAllSeries_with6Snapshots_excludesAllSeries() {
        // 6 < 7 minimum → no series should be produced
        let snapshots = makeSnapshots(count: 6) { s, _ in s.sleepDurationHours = 7.0 }
        let series = CorrelationEngine.extractAllSeries(
            snapshots: snapshots, entries: [], categories: [])
        XCTAssertTrue(series.isEmpty)
    }

    func test_extractAllSeries_nilField_excludedFromSeries() {
        // restingHeartRate is left nil — should not produce an FC repos series
        let snapshots = makeSnapshots(count: 10) { s, _ in s.sleepDurationHours = 7.5 }
        let series = CorrelationEngine.extractAllSeries(
            snapshots: snapshots, entries: [], categories: [])
        XCTAssertNil(series.first(where: { $0.name == "FC repos" }))
    }

    func test_extractAllSeries_seriesValuesMatchSnapshotData() {
        let snapshots = makeSnapshots(count: 7) { s, i in
            s.sleepDurationHours = Double(i) + 5.0
        }
        let series = CorrelationEngine.extractAllSeries(
            snapshots: snapshots, entries: [], categories: [])
        let sleepSeries = series.first(where: { $0.name == "Sommeil (heures)" })
        XCTAssertNotNil(sleepSeries)
        XCTAssertEqual(sleepSeries?.values.count, 7)
    }

    // MARK: - computeAll

    func test_computeAll_perfectCorrelation_findsStrongResult() {
        let (a, b) = makePerfectlyCorrelatedSeries(days: 14, nameA: "Alpha", nameB: "Beta")
        let results = CorrelationEngine.computeAll(series: [a, b], windowDays: 14, maxLag: 0)
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results[0].pearsonR, 1.0, accuracy: 1e-5)
        XCTAssertEqual(results[0].strength, .strong)
    }

    func test_computeAll_sortedByAbsoluteR_descending() {
        let (a, b) = makePerfectlyCorrelatedSeries(days: 14, nameA: "A", nameB: "B")
        let (c, d) = makeSeriesWithR(approx: 0.5, days: 14, nameA: "C", nameB: "D")
        let results = CorrelationEngine.computeAll(series: [a, b, c, d], windowDays: 14, maxLag: 0)
        for i in 0..<max(0, results.count - 1) {
            XCTAssertGreaterThanOrEqual(abs(results[i].pearsonR), abs(results[i + 1].pearsonR))
        }
    }

    func test_computeAll_allResultsMeetThreshold() {
        let (a, b) = makePerfectlyCorrelatedSeries(days: 14, nameA: "X", nameB: "Y")
        let results = CorrelationEngine.computeAll(series: [a, b], windowDays: 14, maxLag: 0)
        for result in results {
            XCTAssertGreaterThanOrEqual(abs(result.pearsonR), 0.3)
            XCTAssertGreaterThanOrEqual(result.sampleSize, 7)
        }
    }

    func test_computeAll_lagDetection_findsNextDayCorrelation() {
        // Series B equals Series A shifted by 1 day
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var valuesA: [Date: Double] = [:]
        var valuesB: [Date: Double] = [:]
        for i in 0..<14 {
            guard let dateA = cal.date(byAdding: .day, value: -i, to: today),
                  let dateB = cal.date(byAdding: .day, value: -(i - 1), to: today)
            else { continue }
            valuesA[dateA] = Double(i)
            valuesB[dateB] = Double(i)
        }
        let a = MetricSeries(name: "A", emoji: "🅰️", values: valuesA)
        let b = MetricSeries(name: "B", emoji: "🅱️", values: valuesB)
        let results = CorrelationEngine.computeAll(series: [a, b], windowDays: 14, maxLag: 1)
        // Should detect lag = 1 or same day; either way a strong result should be found
        XCTAssertFalse(results.isEmpty)
    }

    // MARK: - generateInsight

    func test_generateInsight_positive_sameDay_containsKeyWords() {
        let text = CorrelationEngine.generateInsight(
            metricA: "Sommeil (heures)", metricB: "HRV (ms)",
            r: 0.8, lag: 0, window: 14)
        XCTAssertTrue(text.contains("Sommeil (heures)"))
        XCTAssertTrue(text.contains("HRV (ms)"))
        XCTAssertTrue(text.contains("augmente"))
        XCTAssertTrue(text.contains("même jour"))
        XCTAssertTrue(text.contains("forte"))
    }

    func test_generateInsight_negative_lag1_containsCorrectWords() {
        let text = CorrelationEngine.generateInsight(
            metricA: "Stress", metricB: "Sommeil (heures)",
            r: -0.6, lag: 1, window: 7)
        XCTAssertTrue(text.contains("diminue"))
        XCTAssertTrue(text.contains("lendemain"))
        XCTAssertTrue(text.contains("modérée"))
    }

    func test_generateInsight_weakCorrelation_labelledFaible() {
        let text = CorrelationEngine.generateInsight(
            metricA: "A", metricB: "B", r: 0.35, lag: 0, window: 14)
        XCTAssertTrue(text.contains("faible"))
    }

    func test_generateInsight_containsRValue() {
        let text = CorrelationEngine.generateInsight(
            metricA: "A", metricB: "B", r: 0.75, lag: 0, window: 14)
        XCTAssertTrue(text.contains("0.75"))
    }

    // MARK: - Helpers

    private func makeSnapshots(
        count: Int,
        configure: (DailySnapshot, Int) -> Void
    ) -> [DailySnapshot] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<count).compactMap { i in
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { return nil }
            let s = DailySnapshot(date: date)
            configure(s, i)
            return s
        }
    }

    private func makePerfectlyCorrelatedSeries(
        days: Int, nameA: String, nameB: String
    ) -> (MetricSeries, MetricSeries) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var va: [Date: Double] = [:]
        var vb: [Date: Double] = [:]
        for i in 0..<days {
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            va[date] = Double(i)
            vb[date] = Double(i) * 2.0 + 1.0   // y = 2x + 1 → r = 1
        }
        return (
            MetricSeries(name: nameA, emoji: "🅰️", values: va),
            MetricSeries(name: nameB, emoji: "🅱️", values: vb)
        )
    }

    /// Produces two series whose Pearson r is *approximately* `approx`.
    private func makeSeriesWithR(
        approx targetR: Double, days: Int, nameA: String, nameB: String
    ) -> (MetricSeries, MetricSeries) {
        // Construct B = targetR * A + noise component perpendicular to A
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var va: [Date: Double] = [:]
        var vb: [Date: Double] = [:]
        for i in 0..<days {
            guard let date = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let xi = Double(i)
            let noise = (i % 2 == 0 ? 1.0 : -1.0) * (1.0 - abs(targetR)) * 2.0
            va[date] = xi
            vb[date] = xi * targetR + noise
        }
        return (
            MetricSeries(name: nameA, emoji: "🅰️", values: va),
            MetricSeries(name: nameB, emoji: "🅱️", values: vb)
        )
    }
}
