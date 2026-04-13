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
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(value > minimum ? Color.accentColor : Color.secondary)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: value)
            .disabled(value <= minimum)

            Text("\(Int(value))")
                .font(.title2.weight(.semibold))
                .monospacedDigit()
                .frame(minWidth: 32)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3), value: value)

            Button {
                if value < maximum {
                    value += 1
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(value < maximum ? Color.accentColor : Color.secondary)
            }
            .sensoryFeedback(.impact(weight: .light), trigger: value)
            .disabled(value >= maximum)
        }
    }
}
