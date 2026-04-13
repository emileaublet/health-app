import SwiftUI

struct BooleanToggle: View {
    @Binding var value: Double   // 0 = Non, 1 = Oui

    var isOn: Bool { value == 1 }

    var body: some View {
        HStack(spacing: 8) {
            ToggleChip(label: L10n.no, isSelected: !isOn) {
                value = 0
            }
            ToggleChip(label: L10n.yes, isSelected: isOn) {
                value = 1
            }
        }
    }
}

private struct ToggleChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(label)
                .font(.callout.weight(isSelected ? .semibold : .medium))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .foregroundColor(isSelected ? .white : Color(.label))
                .background(isSelected ? Color.accentColor : Color(.systemGray3))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}
