import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LogViewModel()
    @State private var showingAddCategory = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Navigation de date
                dateNavigator
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))

                Divider()

                // Liste des catégories
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.categories.isEmpty {
                            ForEach(0..<5, id: \.self) { _ in
                                SkeletonRow()
                            }
                        }

                        ForEach(viewModel.categories) { category in
                            CategoryRow(
                                category: category,
                                value: Binding(
                                    get: { viewModel.currentValue(for: category) },
                                    set: { viewModel.setValue($0, for: category) }
                                )
                            )
                        }

                        // Bouton ajouter une catégorie
                        Button {
                            showingAddCategory = true
                        } label: {
                            Label(L10n.addCategory, systemImage: "plus.circle")
                                .font(.callout)
                                .foregroundStyle(Color.accentColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Note du jour
                        noteSection

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle(L10n.logTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditorSheet(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.configure(context: modelContext)
        }
    }

    // MARK: Date navigator

    private var dateNavigator: some View {
        HStack {
            Button {
                viewModel.goToPreviousDay()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            VStack(spacing: 2) {
                Text(dateTitle)
                    .font(.headline)
                Text(viewModel.selectedDate.shortDateString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                viewModel.goToNextDay()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
            }
            .opacity(viewModel.canGoForward ? 1 : 0.3)
            .disabled(!viewModel.canGoForward)
        }
    }

    private var dateTitle: String {
        if viewModel.isToday { return L10n.today }
        if Calendar.current.isDateInYesterday(viewModel.selectedDate) { return L10n.yesterday }
        return viewModel.selectedDate.dayOfWeekString
    }

    // MARK: Note section

    private var noteSection: some View {
        DayNoteField(text: Binding(
            get: { viewModel.entriesForDate.values.first(where: { $0.note != nil })?.note ?? "" },
            set: { viewModel.setDayNote($0) }
        ))
    }
}

// MARK: - CategoryRow

private struct CategoryRow: View {
    let category: TrackingCategory
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(category.emoji)
                    .font(.title3)
                Text(category.name)
                    .font(.callout.weight(.semibold))
                Spacer()
                if category.dataType != .boolean {
                    Text(value.formatted(for: category.dataType))
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(value > 0 ? .primary : .tertiary)
                }
                if value > 0 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.callout)
                        .transition(.scale.combined(with: .opacity))
                }
            }

            inputControl
        }
        .padding(14)
        .background(value > 0 ? Color.accentColor.opacity(0.08) : Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(value > 0 ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1.5))
        .animation(.easeInOut(duration: 0.2), value: value > 0)
        .animation(.easeInOut(duration: 0.15), value: value)
    }

    @ViewBuilder
    private var inputControl: some View {
        switch category.dataType {
        case .counter:
            CounterInput(value: $value)
        case .boolean:
            BooleanToggle(value: $value)
        case .scale:
            ScaleSelector(value: $value)
        }
    }
}
