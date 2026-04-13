import SwiftUI

struct TimeWindowPicker: View {
    @Binding var selectedDays: Int
    let options: [Int] = [7, 14, 30]

    var body: some View {
        Picker(L10n.windowPickerLabel, selection: $selectedDays) {
            ForEach(options, id: \.self) { days in
                Text(L10n.daysSuffix(days)).tag(days)
            }
        }
        .pickerStyle(.segmented)
    }
}
