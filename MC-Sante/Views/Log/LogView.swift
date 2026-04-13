import SwiftUI
import SwiftData

struct LogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LogViewModel()
    @State private var showingAddCategory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Calendar strip (scrolls with content)
                    CalendarStrip(
                        selectedDate: $viewModel.selectedDate,
                        markedDates: viewModel.datesWithEntries
                    )
                    .padding(.vertical, 8)

                    Divider()
                        .padding(.bottom, 4)

                    // Liste des catégories
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !Calendar.current.isDateInToday(viewModel.selectedDate) {
                        Button {
                            viewModel.selectedDate = Calendar.current.startOfDay(for: .now)
                        } label: {
                            Image(systemName: "calendar.badge.clock")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditorSheet(viewModel: viewModel)
            }
            .alert(L10n.saveError, isPresented: $viewModel.showSaveError) {
                Button(L10n.ok) {}
            } message: {
                Text(L10n.saveErrorMessage)
            }
        }
        .onAppear {
            viewModel.configure(context: modelContext)
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            viewModel.onDateChanged()
        }
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
