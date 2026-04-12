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

    /// Retourne nil si moins de 7 points communs.
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

    // MARK: Extract series

    static func extractAllSeries(
        snapshots: [DailySnapshot],
        entries: [DailyEntry],
        categories: [TrackingCategory]
    ) -> [MetricSeries] {
        var series: [MetricSeries] = []

        // Métriques automatiques depuis DailySnapshot
        let snapshotMetrics: [(String, String, (DailySnapshot) -> Double?)] = [
            ("Sommeil (heures)",     "😴", { $0.sleepDurationHours }),
            ("Sommeil REM (min)",    "🌙", { $0.sleepREMMinutes }),
            ("Sommeil profond (min)","💤", { $0.sleepDeepMinutes }),
            ("FC repos",             "❤️", { $0.restingHeartRate }),
            ("HRV (ms)",             "💓", { $0.hrvSDNN }),
            ("Calories actives",     "🔥", { $0.activeCalories }),
            ("Minutes exercice",     "🏃", { $0.exerciseMinutes }),
            ("Humeur (valence)",     "🧠", { $0.moodValence }),
            ("Température (°C)",     "🌡️", { $0.temperatureCelsius }),
            ("Pression (hPa)",       "📊", { $0.pressureHPa }),
            ("Humidité (%)",         "💧", { $0.humidityPercent }),
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
        maxLag: Int = 1
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

                    if let r = pearson(xVals, yVals), abs(r) > abs(bestR) {
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
        let direction = r > 0 ? "augmente" : "diminue"
        let lagText = lag == 0 ? "le même jour" : "le lendemain"
        let strengthText: String
        switch abs(r) {
        case 0.7...: strengthText = "forte"
        case 0.5...: strengthText = "modérée"
        default:     strengthText = "faible"
        }
        let sign = r > 0 ? "+" : ""
        let rFormatted = String(format: "%.2f", r)
        return "Sur les \(window) derniers jours, quand \(metricA) est élevé·e, \(metricB) tend à \(direction) \(lagText). Corrélation \(strengthText) (r=\(sign)\(rFormatted), n=\(window) j)."
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
