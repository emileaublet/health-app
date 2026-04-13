import SwiftUI

struct DayNoteField: View {
    @Binding var text: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(L10n.dayNote, systemImage: "square.and.pencil")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(L10n.dayNotePlaceholder)
                        .foregroundStyle(.tertiary)
                        .font(.callout)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $text)
                    .font(.callout)
                    .frame(minHeight: 72)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 2)
            }
            .padding(8)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
