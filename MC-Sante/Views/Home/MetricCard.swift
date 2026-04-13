import SwiftUI

struct MetricCard: View {
    let emoji: String
    let title: String
    let value: String
    let subtitle: String?
    var accentColor: Color = .accentColor
    var progress: Double? = nil    // 0.0 – 1.0
    var sparklineData: [Double] = []
    var highlightIndex: Int? = nil  // which bar to highlight (current day)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(emoji)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
            }

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(accentColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if sparklineData.count >= 2 {
                MiniBarChart(
                    data: sparklineData,
                    color: accentColor,
                    highlightIndex: highlightIndex
                )
                .frame(height: 28)
            } else if let progress {
                ProgressView(value: progress)
                    .tint(accentColor)
                    .scaleEffect(y: 1.5, anchor: .center)
            }
        }
        .padding(14)
        .frame(minHeight: 140)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(accentColor.opacity(0.15), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Mini bar chart (7 bars, highlighted current day)

struct MiniBarChart: View {
    let data: [Double]
    var color: Color = .accentColor
    var highlightIndex: Int? = nil

    var body: some View {
        GeometryReader { geo in
            let maxVal = data.max() ?? 1
            let safeMax = maxVal == 0 ? 1.0 : maxVal
            let barSpacing: CGFloat = 2
            let totalSpacing = barSpacing * CGFloat(max(data.count - 1, 0))
            let barWidth = (geo.size.width - totalSpacing) / CGFloat(max(data.count, 1))

            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, val in
                    let ratio = CGFloat(val / safeMax)
                    let barHeight = max(geo.size.height * ratio, 3)
                    let isHighlighted = index == highlightIndex

                    ZStack(alignment: .top) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                isHighlighted
                                    ? LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                                    : LinearGradient(colors: [color.opacity(0.45), color.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                            )
                            .frame(width: barWidth, height: barHeight)

                        if isHighlighted {
                            Circle()
                                .fill(color)
                                .frame(width: 5, height: 5)
                                .offset(y: -7)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

// MARK: - Missing data variant

struct MetricCardMissing: View {
    let emoji: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(emoji)
                    .font(.title2)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "minus.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text("—")
                .font(.title3.weight(.bold))
                .foregroundStyle(.tertiary)

            Text("—")
                .font(.caption2)
                .foregroundStyle(.quaternary)

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(minHeight: 140)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
