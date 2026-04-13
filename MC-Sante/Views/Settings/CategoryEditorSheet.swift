import SwiftUI

struct CategoryEditorSheet: View {
    var viewModel: LogViewModel
    var existing: TrackingCategory? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name: String = ""
    @State private var emoji: String = "📊"
    @State private var dataType: MetricDataType = .counter
    @State private var showingEmojiPicker = false

    private var isEditing: Bool { existing != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.nameAndIcon) {
                    HStack {
                        Button {
                            showingEmojiPicker = true
                        } label: {
                            Text(emoji)
                                .font(.largeTitle)
                                .frame(width: 48, height: 48)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        TextField(L10n.categoryNamePlaceholder, text: $name)
                            .font(.body)
                    }
                }

                Section(L10n.dataTypeSection) {
                    Picker("Type", selection: $dataType) {
                        ForEach(MetricDataType.allCases, id: \.self) { type in
                            Label(type.label, systemImage: typeIcon(type))
                                .tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()

                    typeHint
                }

                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            if let cat = existing {
                                viewModel.archiveCategory(cat)
                            }
                            dismiss()
                        } label: {
                            Label(L10n.archiveCategory, systemImage: "archivebox")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? L10n.editCategory : L10n.newCategory)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? L10n.editCategory : L10n.create) {
                        if isEditing, let cat = existing {
                            cat.name = name
                            cat.emoji = emoji
                            cat.dataType = dataType
                            try? modelContext.save()
                        } else {
                            viewModel.createCategory(
                                name: name,
                                emoji: emoji,
                                dataType: dataType
                            )
                        }
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPicker(selectedEmoji: $emoji)
            }
            .onAppear {
                if let cat = existing {
                    name     = cat.name
                    emoji    = cat.emoji
                    dataType = cat.dataType
                }
            }
        }
    }

    @ViewBuilder
    private var typeHint: some View {
        switch dataType {
        case .counter:
            Text(L10n.hintCounter)
                .font(.caption).foregroundStyle(.secondary)
        case .boolean:
            Text(L10n.hintBoolean)
                .font(.caption).foregroundStyle(.secondary)
        case .scale:
            Text(L10n.hintScale)
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func typeIcon(_ type: MetricDataType) -> String {
        switch type {
        case .counter: return "number.circle"
        case .boolean: return "checkmark.circle"
        case .scale:   return "slider.horizontal.3"
        }
    }
}
