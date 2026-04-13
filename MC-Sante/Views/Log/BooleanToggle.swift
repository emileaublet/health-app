import SwiftUI

struct BooleanToggle: View {
    @Binding var value: Double   // 0 = Non, 1 = Oui

    var isOn: Bool { value == 1 }

    var body: some View {
        HStack(spacing: 8) {
            ToggleChip(label: L10n.no, isSelected: !isOn, isAffirmative: false) {
                value = 0
            }
            ToggleChip(label: L10n.yes, isSelected: isOn, isAffirmative: true) {
                value = 1
            }
        }
    }
}

private struct ToggleChip: View {
    let label: String
    let isSelected: Bool
    let isAffirmative: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }) {
            Text(label)
                .font(.callout.weight(isSelected ? .semibold : .medium))
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .foregroundColor(isSelected ? .white : Color(.label))
                .background(
                    isSelected
                        ? (isAffirmative ? Color.green : Color.red)
                        : Color(.tertiarySystemBackground)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        .animation(.spring(response: 0.25), value: isSelected)
    }
}
