import SwiftUI

struct TimeWindowPicker: View {
    @Binding var selectedDays: Int
    let options: [Int] = [7, 14, 30]

    var body: some View {
        Picker("Fenêtre", selection: $selectedDays) {
            ForEach(options, id: \.self) { days in
                Text("\(days) j").tag(days)
            }
        }
        .pickerStyle(.segmented)
    }
}
