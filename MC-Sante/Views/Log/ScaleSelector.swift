import SwiftUI

struct ScaleSelector: View {
    @Binding var value: Double   // 0 = non renseigné, 1-5

    private let levels = 1...5

    var body: some View {
        HStack(spacing: 8) {
            ForEach(levels, id: \.self) { level in
                ScaleCircle(
                    level: level,
                    isSelected: Int(value) == level
                ) {
                    value = value == Double(level) ? 0 : Double(level)
                }
            }
        }
    }
}

private struct ScaleCircle: View {
    let level: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            ZStack {
                Circle()
                    .fill(isSelected ? fillColor : Color(.secondarySystemBackground))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .strokeBorder(isSelected ? fillColor : Color(.systemGray4), lineWidth: 1.5)
                    }

                Text("\(level)")
                    .font(.callout.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : .primary)
            }
        }
        .sensoryFeedback(.selection, trigger: isSelected)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
    }

    private var fillColor: Color {
        switch level {
        case 1: return .red.opacity(0.8)
        case 2: return .orange.opacity(0.8)
        case 3: return .yellow.opacity(0.8)
        case 4: return .green.opacity(0.7)
        case 5: return .green
        default: return .accentColor
        }
    }
}
