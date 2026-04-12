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
                Section("Nom et icône") {
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
                        TextField("Nom de la catégorie", text: $name)
                            .font(.body)
                    }
                }

                Section("Type de donnée") {
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
                            Label("Archiver cette catégorie", systemImage: "archivebox")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Modifier" : "Nouvelle catégorie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Modifier" : "Créer") {
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
            Text("Ex : 2 cafés, 3 verres d'eau…")
                .font(.caption).foregroundStyle(.secondary)
        case .boolean:
            Text("Ex : A mangé du gluten ? Oui / Non")
                .font(.caption).foregroundStyle(.secondary)
        case .scale:
            Text("Ex : Stress de 1 (très bas) à 5 (très élevé)")
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
