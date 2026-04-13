import SwiftUI

struct InsightCard: View {
    let insight: CorrelationResult

    var body: some View {
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
                Text("r = \(String(format: "%+.2f", insight.pearsonR))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(L10n.sampleDays(insight.sampleSize))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            Color.correlationColor(for: insight.pearsonR).opacity(0.4),
                            lineWidth: 1.5
                        )
                }
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
        case .weak:     return .yellow
        case .moderate: return .orange
        case .strong:   return .red
        }
    }
}
