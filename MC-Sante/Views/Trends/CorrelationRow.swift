import SwiftUI

struct CorrelationRow: View {
    let result: CorrelationResult

    var body: some View {
        HStack(spacing: 12) {
            // Strength indicator bar
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.correlationColor(for: result.pearsonR))
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(result.emojiA.isEmpty ? "📊" : result.emojiA)
                    Text(result.metricA)
                        .fontWeight(.medium)
                    Image(systemName: result.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(result.isPositive ? .green : .red)
                        .font(.caption)
                    Text(result.emojiB.isEmpty ? "📊" : result.emojiB)
                    Text(result.metricB)
                        .fontWeight(.medium)
                }
                .font(.callout)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

                HStack(spacing: 6) {
                    StrengthBadge(strength: result.strength)
                    if result.lagDays > 0 {
                        Text("↺ \(result.lagDays) j")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("r = \(String(format: "%+.2f", result.pearsonR))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
    }
}
