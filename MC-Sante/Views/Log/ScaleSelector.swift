import SwiftUI

struct ScaleSelector: View {
    @Binding var value: Double   // 0 = non renseigné, 1-5

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("1")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Slider(
                    value: Binding(
                        get: { value == 0 ? 3 : value },
                        set: { value = min(max($0.rounded(), 1), 5) }
                    ),
                    in: 1...5,
                    step: 1
                )
                .tint(sliderColor)

                Text("5")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Button {
                    value = 0
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(value == 0 ? .tertiary : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear value")
                .disabled(value == 0)
            }

            HStack {
                Text(value == 0 ? "—" : "\(Int(value))")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(value == 0 ? .secondary : .primary)
                Spacer()
            }
        }
    }

    private var fillColor: Color {
        switch Int(value == 0 ? 3 : value) {
        case 1: return .red.opacity(0.8)
        case 2: return .orange.opacity(0.8)
        case 3: return .yellow.opacity(0.8)
        case 4: return .green.opacity(0.7)
        case 5: return .green
        default: return .accentColor
        }
    }

    private var sliderColor: Color {
        value == 0 ? .accentColor : fillColor
    }
}
