import SwiftUI

struct CounterInput: View {
    @Binding var value: Double
    var minimum: Double = 0
    var maximum: Double = 20

    var body: some View {
        HStack(spacing: 16) {
            Button {
                if value > minimum {
                    value -= 1
                }
            } label: {
                Image(systemName: "minus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(value > minimum ? Color.accentColor : Color.secondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(.tertiarySystemBackground)))
            }
            .sensoryFeedback(.impact(weight: .light), trigger: value)
            .disabled(value <= minimum)

            Text("\(Int(value))")
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .frame(minWidth: 32)
                .foregroundStyle(value > 0 ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)

            Button {
                if value < maximum {
                    value += 1
                }
            } label: {
                Image(systemName: "plus")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(value < maximum ? Color.accentColor : Color.secondary)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color(.tertiarySystemBackground)))
            }
            .sensoryFeedback(.increase, trigger: value)
            .disabled(value >= maximum)
        }
    }
}
