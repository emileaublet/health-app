import SwiftUI

struct EmojiPicker: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var recentEmojis: [String] = []

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    private var categorizedEmojis: [(String, [String])] {
        [
            (L10n.emojiRecents,  []),
            (L10n.emojiHealth,   ["💊","🩺","🩻","🩹","🧬","🫀","🧠","🦷","🦴","👁","💉","🩸","🌡️","⚕️"]),
            (L10n.emojiFood,     ["☕","🍵","🧃","🥤","🍎","🥑","🥦","🥗","🍕","🍔","🧁","🍬","🍫","🥐","🥩","🐟","🥚","🥛","🍷","🍺"]),
            (L10n.emojiActivity, ["🏃","🚴","🏊","🧘","🏋️","⚽","🎾","🧗","🤸","🏔️","🚶","🤾","🏄","🛹","🤺"]),
            (L10n.emojiEmotions, ["😰","😤","😌","😊","😄","😢","😡","😴","🥱","😮‍💨","🤩","😔","🤯","😇","🥳"]),
            (L10n.emojiNature,   ["🌡️","☀️","🌧️","❄️","🌬️","⛅","🌊","🌿","🍃","🌸","🌙","⭐","🌈","🌻"]),
            (L10n.emojiMisc,     ["⚡","🔥","💧","✨","🎯","🏆","💪","🛌","🚿","📊","📈","🔬","🧪","💡","⏰"]),
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Barre de recherche
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField(L10n.searchEmoji, text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal)
                .padding(.top)

                if searchText.isEmpty {
                    // Grille par catégories
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            if !recentEmojis.isEmpty {
                                emojiSection(title: L10n.emojiRecents, emojis: recentEmojis)
                            }
                            ForEach(categorizedEmojis.dropFirst(), id: \.0) { title, emojis in
                                emojiSection(title: title, emojis: emojis)
                            }
                        }
                        .padding()
                    }
                } else {
                    // Résultats de recherche (filtrage simplifié par description)
                    let results = searchResults
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(results, id: \.self) { emoji in
                                emojiButton(emoji)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(L10n.chooseEmoji)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
            }
        }
        .onAppear { loadRecentEmojis() }
    }

    // MARK: Sub-views

    private func emojiSection(title: String, emojis: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(emojis, id: \.self) { emoji in
                    emojiButton(emoji)
                }
            }
        }
    }

    private func emojiButton(_ emoji: String) -> some View {
        Button {
            selectedEmoji = emoji
            saveToRecents(emoji)
            dismiss()
        } label: {
            Text(emoji)
                .font(.title2)
                .frame(width: 36, height: 36)
                .background(selectedEmoji == emoji ? Color.accentColor.opacity(0.2) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    // MARK: Search

    private var searchResults: [String] {
        let all = categorizedEmojis.flatMap(\.1)
        guard !searchText.isEmpty else { return all }
        // Simple keyword filter on the emoji itself
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    // MARK: Recents

    private func loadRecentEmojis() {
        recentEmojis = UserDefaults.standard.stringArray(forKey: "recentEmojis") ?? []
    }

    private func saveToRecents(_ emoji: String) {
        var recents = recentEmojis.filter { $0 != emoji }
        recents.insert(emoji, at: 0)
        recentEmojis = Array(recents.prefix(16))
        UserDefaults.standard.set(recentEmojis, forKey: "recentEmojis")
    }
}
