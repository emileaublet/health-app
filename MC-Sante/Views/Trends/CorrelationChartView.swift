import SwiftUI
import Charts

struct CorrelationChartView: View {
    let result: CorrelationResult
    let seriesA: [(Date, Double)]
    let seriesB: [(Date, Double)]

    @State private var chartMode: ChartMode = .timeline

    enum ChartMode: String, CaseIterable {
        case timeline = "Chronologie"
        case scatter  = "Nuage"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Mode picker
            Picker("Mode", selection: $chartMode) {
                ForEach(ChartMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch chartMode {
            case .timeline: timelineChart
            case .scatter:  scatterChart
            }

            // Disclaimer
            Text("⚠️ Corrélation statistique ≠ causalité. n = \(result.sampleSize) jours.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: Timeline chart (dual normalised series)

    private var timelineChart: some View {
        let normA = CorrelationEngine.zNormalize(seriesA)
        let normB = CorrelationEngine.zNormalize(seriesB)

        return Chart {
            ForEach(normA, id: \.0) { date, value in
                LineMark(
                    x: .value("Date", date),
                    y: .value(result.metricA, value),
                    series: .value("Série", result.metricA)
                )
                .foregroundStyle(Color.metricColor(for: result.metricA))
                .interpolationMethod(.catmullRom)
                AreaMark(
                    x: .value("Date", date),
                    y: .value(result.metricA, value),
                    series: .value("Série", result.metricA)
                )
                .foregroundStyle(
                    Color.metricColor(for: result.metricA).opacity(0.08)
                )
                .interpolationMethod(.catmullRom)
            }

            ForEach(normB, id: \.0) { date, value in
                LineMark(
                    x: .value("Date", date),
                    y: .value(result.metricB, value),
                    series: .value("Série", result.metricB)
                )
                .foregroundStyle(Color.metricColor(for: result.metricB))
                .interpolationMethod(.catmullRom)
            }
        }
        .chartLegend(position: .top, alignment: .leading, spacing: 8)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, seriesA.count / 5))) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month(.abbreviated))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 220)
        .chartAnnotation(position: .overlay, alignment: .topLeading) {
            if result.lagDays > 0 {
                Text("↺ Décalage \(result.lagDays) j")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(4)
            }
        }
    }

    // MARK: Scatter chart

    private var scatterChart: some View {
        let pairs = alignedPairs()

        return Chart {
            ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                PointMark(
                    x: .value(result.metricA, pair.0),
                    y: .value(result.metricB, pair.1)
                )
                .foregroundStyle(Color.metricColor(for: result.metricA).opacity(0.7))
                .symbolSize(60)
            }

            // Trend line
            if let (slope, intercept) = linearRegression(pairs) {
                if let minX = pairs.map(\.0).min(),
                   let maxX = pairs.map(\.0).max() {
                    LineMark(
                        x: .value(result.metricA, minX),
                        y: .value("Tendance", slope * minX + intercept),
                        series: .value("Série", "Tendance")
                    )
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

                    LineMark(
                        x: .value(result.metricA, maxX),
                        y: .value("Tendance", slope * maxX + intercept),
                        series: .value("Série", "Tendance")
                    )
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                }
            }
        }
        .chartXAxisLabel(result.metricA)
        .chartYAxisLabel(result.metricB)
        .chartOverlay { proxy in
            Text("r = \(String(format: "%+.2f", result.pearsonR))")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(Color.correlationColor(for: result.pearsonR))
                .padding(6)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 220)
    }

    // MARK: Helpers

    private func alignedPairs() -> [(Double, Double)] {
        let dictA = Dictionary(uniqueKeysWithValues: seriesA)
        let dictB = Dictionary(uniqueKeysWithValues: seriesB)
        let cal = Calendar.current
        return dictA.compactMap { date, aVal in
            let laggedDate = cal.date(byAdding: .day, value: result.lagDays, to: date)!
            guard let bVal = dictB[laggedDate] else { return nil }
            return (aVal, bVal)
        }
    }

    private func linearRegression(_ pairs: [(Double, Double)]) -> (slope: Double, intercept: Double)? {
        guard pairs.count >= 2 else { return nil }
        let n = Double(pairs.count)
        let sumX = pairs.map(\.0).reduce(0, +)
        let sumY = pairs.map(\.1).reduce(0, +)
        let sumXY = pairs.map { $0.0 * $0.1 }.reduce(0, +)
        let sumX2 = pairs.map { $0.0 * $0.0 }.reduce(0, +)
        let denom = n * sumX2 - sumX * sumX
        guard denom != 0 else { return nil }
        let slope = (n * sumXY - sumX * sumY) / denom
        let intercept = (sumY - slope * sumX) / n
        return (slope, intercept)
    }
}
