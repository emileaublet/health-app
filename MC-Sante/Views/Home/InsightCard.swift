import SwiftUI

struct InsightCard: View {
    let insight: CorrelationResult

    private var accentColor: Color {
        Color.correlationColor(for: insight.pearsonR)
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Card background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(accentColor.opacity(0.4), lineWidth: 1.5)
                }

            // Left accent bar
            Rectangle()
                .fill(accentColor)
                .frame(width: 4)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 16, bottomLeadingRadius: 16,
                        bottomTrailingRadius: 0, topTrailingRadius: 0
                    )
                )

            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Label(L10n.correlationDetected, systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    StrengthBadge(strength: insight.strength)
                }

                // Metrics
                HStack(spacing: 4) {
                    Text(insight.emojiA.isEmpty ? "📊" : insight.emojiA)
                    Text(insight.metricA)
                        .fontWeight(.medium)
                    Image(systemName: insight.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(insight.isPositive ? .green : .red)
                        .font(.caption)
                    Text(insight.emojiB.isEmpty ? "📊" : insight.emojiB)
                    Text(insight.metricB)
                        .fontWeight(.medium)
                }
                .font(.subheadline)

                // Insight text
                Text(insight.insightText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Footer
                HStack(spacing: 4) {
                    if insight.lagDays > 0 {
                        Label(L10n.insightLag(insight.lagDays), systemImage: "clock.arrow.circlepath")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    // Prominent correlation coefficient with direction indicator
                    HStack(spacing: 3) {
                        Image(systemName: insight.pearsonR > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(accentColor)
                        Text("r = \(String(format: "%+.2f", insight.pearsonR))")
                            .font(.title3.weight(.bold).monospacedDigit())
                            .foregroundStyle(accentColor)
                    }
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(L10n.sampleDays(insight.sampleSize))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .padding(.leading, 4) // offset content past the accent bar
        }
    }
}

// MARK: - StrengthBadge

struct StrengthBadge: View {
    let strength: CorrelationStrength

    var body: some View {
        Text(strength.localizedLabel)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch strength {
        case .weak:     return .gray
        case .moderate: return .orange
        case .strong:   return .green
        }
    }
}
