import SwiftUI
import Charts

// MARK: - Sleep Chart (stacked bars: Core / Deep / REM)

struct SleepChartView: View {
    let snapshots: [DailySnapshot]
    let selectedDate: Date

    private struct SleepBar: Identifiable {
        let id = UUID()
        let date: Date
        let stage: String
        let minutes: Double
    }

    private var bars: [SleepBar] {
        snapshots.flatMap { snap in [
            SleepBar(date: snap.date, stage: "Core", minutes: snap.sleepCoreMinutes ?? 0),
            SleepBar(date: snap.date, stage: "Deep", minutes: snap.sleepDeepMinutes ?? 0),
            SleepBar(date: snap.date, stage: "REM",  minutes: snap.sleepREMMinutes  ?? 0),
        ]}
    }

    var body: some View {
        Chart(bars) { bar in
            BarMark(
                x: .value("Day", bar.date, unit: .day),
                y: .value("min", bar.minutes)
            )
            .foregroundStyle(by: .value("Stage", bar.stage))
            .cornerRadius(3)
            .opacity(Calendar.current.isDate(bar.date, inSameDayAs: selectedDate) ? 1.0 : 0.5)
        }
        .chartForegroundStyleScale([
            "Core": Color.teal,
            "Deep": Color.blue,
            "REM":  Color.indigo,
        ])
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v / 60))h").font(.caption2)
                    }
                }
            }
        }
    }
}

// MARK: - Cardiac Chart (dual line: Resting HR + HRV)

struct CardiacChartView: View {
    let snapshots: [DailySnapshot]
    let selectedDate: Date

    private struct HeartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let metric: String
        let value: Double
    }

    private var points: [HeartPoint] {
        snapshots.flatMap { snap -> [HeartPoint] in
            var pts: [HeartPoint] = []
            if let hr  = snap.restingHeartRate { pts.append(.init(date: snap.date, metric: "HR",  value: hr))  }
            if let hrv = snap.hrvSDNN          { pts.append(.init(date: snap.date, metric: "HRV", value: hrv)) }
            return pts
        }
    }

    var body: some View {
        Chart(points) { pt in
            LineMark(
                x: .value("Day", pt.date, unit: .day),
                y: .value("Val", pt.value)
            )
            .foregroundStyle(by: .value("Metric", pt.metric))
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2))
            .symbol(Circle())
            .symbolSize(pt.metric == "HR" ? 28 : 18)
            .opacity(Calendar.current.isDate(pt.date, inSameDayAs: selectedDate) ? 1.0 : 0.65)
        }
        .chartForegroundStyleScale(["HR": Color.heartColor, "HRV": Color.pink])
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))").font(.caption2)
                    }
                }
            }
        }
    }
}

// MARK: - Activity Chart (bars: Calories normalised; line: Exercise normalised)

struct ActivityChartView: View {
    let snapshots: [DailySnapshot]
    let selectedDate: Date

    private var calMax: Double { max(snapshots.compactMap(\.activeCalories).max() ?? 1, 1) }
    private var exMax:  Double { max(snapshots.compactMap(\.exerciseMinutes).max() ?? 1, 1) }

    var body: some View {
        Chart {
            ForEach(snapshots, id: \.id) { snap in
                if let cal = snap.activeCalories {
                    BarMark(
                        x: .value("Day", snap.date, unit: .day),
                        y: .value("%", cal / calMax)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [.activityColor, .activityColor.opacity(0.55)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .cornerRadius(4)
                    .opacity(Calendar.current.isDate(snap.date, inSameDayAs: selectedDate) ? 1.0 : 0.5)
                }
                if let ex = snap.exerciseMinutes {
                    LineMark(
                        x: .value("Day", snap.date, unit: .day),
                        y: .value("%", ex / exMax)
                    )
                    .foregroundStyle(Color.green)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                    .symbol(Circle())
                    .symbolSize(20)
                }
            }
        }
        .chartYScale(domain: 0...1.05)
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .font(.caption2)
            }
        }
    }
}

// MARK: - Weather Chart (area + line: Temperature)

struct WeatherChartView: View {
    let snapshots: [DailySnapshot]
    let selectedDate: Date

    var body: some View {
        Chart {
            ForEach(snapshots, id: \.id) { snap in
                if let temp = snap.temperatureCelsius {
                    AreaMark(
                        x: .value("Day", snap.date, unit: .day),
                        y: .value("°C", temp)
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [Color.weatherColor.opacity(0.35), Color.weatherColor.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Day", snap.date, unit: .day),
                        y: .value("°C", temp)
                    )
                    .foregroundStyle(Color.weatherColor)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    .interpolationMethod(.catmullRom)
                    .symbol(Circle())
                    .symbolSize(30)
                    .opacity(Calendar.current.isDate(snap.date, inSameDayAs: selectedDate) ? 1.0 : 0.7)
                }
            }
        }
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(v.oneDecimal)°").font(.caption2)
                    }
                }
            }
        }
    }
}

// MARK: - Mood Chart (area + line: Valence –1 … +1)

struct MoodChartView: View {
    let snapshots: [DailySnapshot]
    let selectedDate: Date

    var body: some View {
        Chart {
            RuleMark(y: .value("Neutral", 0.0))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                .foregroundStyle(Color.secondary.opacity(0.4))

            ForEach(snapshots.filter { $0.moodValence != nil }, id: \.id) { snap in
                let v = snap.moodValence!
                AreaMark(
                    x: .value("Day", snap.date, unit: .day),
                    yStart: .value("Zero", 0.0),
                    yEnd:   .value("Val",  v)
                )
                .foregroundStyle(LinearGradient(
                    colors: v >= 0
                        ? [Color.moodColor.opacity(0.35), Color.moodColor.opacity(0.0)]
                        : [Color.red.opacity(0.0), Color.red.opacity(0.25)],
                    startPoint: .top, endPoint: .bottom
                ))
                .interpolationMethod(.catmullRom)

                LineMark(
                    x: .value("Day", snap.date, unit: .day),
                    y: .value("Val", v)
                )
                .foregroundStyle(Color.moodColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
                .symbol(Circle())
                .symbolSize(30)
                .opacity(Calendar.current.isDate(snap.date, inSameDayAs: selectedDate) ? 1.0 : 0.65)
            }
        }
        .chartYScale(domain: -1...1)
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .font(.caption2)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [-1, 0, 1]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(v == 0 ? "0" : v > 0 ? "+1" : "−1").font(.caption2)
                    }
                }
            }
        }
    }
}

// MARK: - Cycle Chart (bars: Flow intensity 0–4)

struct CycleChartView: View {
    let snapshots: [DailySnapshot]
    let selectedDate: Date

    var body: some View {
        Chart {
            ForEach(snapshots, id: \.id) { snap in
                BarMark(
                    x: .value("Day", snap.date, unit: .day),
                    y: .value("Flow", Double(snap.menstrualFlowRaw ?? 0))
                )
                .foregroundStyle(LinearGradient(
                    colors: [Color.pink, Color.pink.opacity(0.5)],
                    startPoint: .top, endPoint: .bottom
                ))
                .cornerRadius(4)
                .opacity(Calendar.current.isDate(snap.date, inSameDayAs: selectedDate) ? 1.0 : 0.5)
            }
        }
        .chartYScale(domain: 0...4)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
                    .font(.caption2)
            }
        }
    }
}
