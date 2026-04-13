import Foundation
import SwiftData

// MARK: - MetricSeries

struct MetricSeries {
    let name: String
    let emoji: String
    let values: [Date: Double]  // startOfDay → valeur
}

// MARK: - CorrelationEngine

enum CorrelationEngine {

    // MARK: Pearson coefficient

    /// Returns nil if fewer than 7 common data points.
    static func pearson(_ x: [Double], _ y: [Double]) -> Double? {
        guard x.count == y.count, x.count >= 7 else { return nil }

        let n = Double(x.count)
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        var numerator: Double = 0
        var denomX: Double = 0
        var denomY: Double = 0

        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            numerator += dx * dy
            denomX += dx * dx
            denomY += dy * dy
        }

        let denominator = sqrt(denomX * denomY)
        guard denominator > 0 else { return nil }
        return numerator / denominator
    }

    // MARK: Spearman rank correlation

    /// Computes Spearman's rank correlation — captures non-linear monotonic relationships.
    /// Returns nil if fewer than 7 data points.
    static func spearman(_ x: [Double], _ y: [Double]) -> Double? {
        guard x.count == y.count, x.count >= 7 else { return nil }
        let rankedX = fractionalRanks(x)
        let rankedY = fractionalRanks(y)
        return pearson(rankedX, rankedY)
    }

    /// Assigns fractional ranks to values (handles ties by averaging).
    private static func fractionalRanks(_ values: [Double]) -> [Double] {
        let indexed = values.enumerated().sorted { $0.element < $1.element }
        var ranks = [Double](repeating: 0, count: values.count)

        var i = 0
        while i < indexed.count {
            var j = i
            // Find all tied values
            while j < indexed.count && indexed[j].element == indexed[i].element {
                j += 1
            }
            // Average rank for tied values
            let avgRank = Double(i + j + 1) / 2.0
            for k in i..<j {
                ranks[indexed[k].offset] = avgRank
            }
            i = j
        }
        return ranks
    }

    // MARK: Extract series

    static func extractAllSeries(
        snapshots: [DailySnapshot],
        entries: [DailyEntry],
        categories: [TrackingCategory]
    ) -> [MetricSeries] {
        var series: [MetricSeries] = []

        // Métriques automatiques depuis DailySnapshot
        let isFrench = LocalizationManager.shared.language == .french
        let snapshotMetrics: [(String, String, (DailySnapshot) -> Double?)] = [
            (isFrench ? "Sommeil (heures)"      : "Sleep (hours)",       "😴", { $0.sleepDurationHours }),
            (isFrench ? "Sommeil REM (min)"     : "REM Sleep (min)",     "🌙", { $0.sleepREMMinutes }),
            (isFrench ? "Sommeil profond (min)" : "Deep Sleep (min)",    "💤", { $0.sleepDeepMinutes }),
            (isFrench ? "FC repos"              : "Resting HR",          "❤️", { $0.restingHeartRate }),
            ("HRV (ms)",                                                  "💓", { $0.hrvSDNN }),
            (isFrench ? "Calories actives"      : "Active Calories",     "🔥", { $0.activeCalories }),
            (isFrench ? "Minutes exercice"      : "Exercise (min)",      "🏃", { $0.exerciseMinutes }),
            (isFrench ? "Humeur (valence)"      : "Mood (valence)",      "🧠", { $0.moodValence }),
            (isFrench ? "Systolique (mmHg)"     : "Systolic (mmHg)",     "🫀", { $0.systolic }),
            (isFrench ? "Diastolique (mmHg)"    : "Diastolic (mmHg)",    "💉", { $0.diastolic }),
            (isFrench ? "Température (°C)"      : "Temperature (°C)",    "🌡️", { $0.temperatureCelsius }),
            (isFrench ? "Pression (hPa)"        : "Pressure (hPa)",     "📊", { $0.pressureHPa }),
            (isFrench ? "Humidité (%)"          : "Humidity (%)",        "💧", { $0.humidityPercent }),
        ]

        for (name, emoji, extractor) in snapshotMetrics {
            var values: [Date: Double] = [:]
            for snapshot in snapshots {
                if let val = extractor(snapshot) {
                    values[snapshot.date] = val
                }
            }
            if values.count >= 7 {
                series.append(MetricSeries(name: name, emoji: emoji, values: values))
            }
        }

        // Métriques manuelles depuis DailyEntry par catégorie
        for category in categories where category.isActive {
            var values: [Date: Double] = [:]
            for entry in entries where entry.category?.id == category.id {
                values[entry.date] = entry.value
            }
            if values.count >= 7 {
                series.append(MetricSeries(name: category.name, emoji: category.emoji, values: values))
            }
        }

        return series
    }

    // MARK: Compute correlations

    static func computeAll(
        series: [MetricSeries],
        windowDays: Int = 14,
        maxLag: Int = 2
    ) -> [CorrelationResult] {
        var results: [CorrelationResult] = []
        let cal = Calendar.current
        let cutoffBase = cal.date(byAdding: .day, value: -windowDays, to: .now) ?? .now
        let cutoffDate = cal.startOfDay(for: cutoffBase)

        for i in 0..<series.count {
            for j in (i + 1)..<series.count {
                let a = series[i]
                let b = series[j]

                var bestR: Double = 0
                var bestLag: Int = 0
                var bestSize: Int = 0

                for lag in 0...maxLag {
                    var xVals: [Double] = []
                    var yVals: [Double] = []

                    for (date, xVal) in a.values {
                        guard date >= cutoffDate else { continue }
                        guard let laggedDate = cal.date(byAdding: .day, value: lag, to: date) else { continue }
                        if let yVal = b.values[laggedDate] {
                            xVals.append(xVal)
                            yVals.append(yVal)
                        }
                    }

                    // Use the strongest of Pearson (linear) and Spearman (monotonic non-linear)
                    let candidates = [
                        pearson(xVals, yVals),
                        spearman(xVals, yVals),
                    ].compactMap { $0 }

                    if let r = candidates.max(by: { abs($0) < abs($1) }), abs(r) > abs(bestR) {
                        bestR = r
                        bestLag = lag
                        bestSize = xVals.count
                    }
                }

                guard abs(bestR) >= 0.3, bestSize >= 7 else { continue }

                let insight = generateInsight(
                    metricA: a.name, metricB: b.name,
                    r: bestR, lag: bestLag, window: windowDays
                )

                results.append(CorrelationResult(
                    metricA: a.name, metricB: b.name,
                    emojiA: a.emoji, emojiB: b.emoji,
                    pearsonR: bestR, sampleSize: bestSize,
                    lagDays: bestLag, windowDays: windowDays,
                    insightText: insight
                ))
            }
        }

        return results.sorted { abs($0.pearsonR) > abs($1.pearsonR) }
    }

    // MARK: Insight text

    static func generateInsight(
        metricA: String,
        metricB: String,
        r: Double,
        lag: Int,
        window: Int
    ) -> String {
        let sign = r > 0 ? "+" : ""
        let rFormatted = String(format: "%.2f", r)

        if LocalizationManager.shared.language == .french {
            let direction = r > 0 ? "augmente" : "diminue"
            let lagText: String
            switch lag {
            case 0: lagText = "le même jour"
            case 1: lagText = "le lendemain"
            default: lagText = "\(lag) jours après"
            }
            let strengthText: String
            switch abs(r) {
            case 0.7...: strengthText = "forte"
            case 0.5...: strengthText = "modérée"
            default:     strengthText = "faible"
            }
            return "Sur les \(window) derniers jours, quand \(metricA) est élevé·e, \(metricB) tend à \(direction) \(lagText). Corrélation \(strengthText) (r=\(sign)\(rFormatted), n=\(window) j)."
        } else {
            let direction = r > 0 ? "increase" : "decrease"
            let lagText: String
            switch lag {
            case 0: lagText = "on the same day"
            case 1: lagText = "the next day"
            default: lagText = "\(lag) days later"
            }
            let strengthText: String
            switch abs(r) {
            case 0.7...: strengthText = "strong"
            case 0.5...: strengthText = "moderate"
            default:     strengthText = "weak"
            }
            return "Over the last \(window) days, when \(metricA) is high, \(metricB) tends to \(direction) \(lagText). \(strengthText.capitalized) correlation (r=\(sign)\(rFormatted), n=\(window) d)."
        }
    }

    // MARK: Z-score normalisation (for chart display)

    static func zNormalize(_ values: [(Date, Double)]) -> [(Date, Double)] {
        guard values.count > 1 else { return values }
        let vals = values.map(\.1)
        let mean = vals.reduce(0, +) / Double(vals.count)
        let variance = vals.map { pow($0 - mean, 2) }.reduce(0, +) / Double(vals.count)
        let stddev = sqrt(variance)
        guard stddev > 0 else { return values.map { ($0.0, 0) } }
        return values.map { ($0.0, ($0.1 - mean) / stddev) }
    }
}
