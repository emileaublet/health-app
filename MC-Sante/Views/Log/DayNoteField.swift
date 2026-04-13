import SwiftUI

struct DayNoteField: View {
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()

            HStack {
                Label(L10n.dayNote, systemImage: "square.and.pencil")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(min(text.count, 300))/300")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(L10n.dayNotePlaceholder)
                        .foregroundStyle(.tertiary)
                        .font(.callout)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.callout)
                    .frame(minHeight: 72)
                    .scrollContentBackground(.hidden)
                    .padding(10)
            }
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
