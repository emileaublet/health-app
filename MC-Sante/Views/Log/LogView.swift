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
            .navigationTitle(viewModel.selectedDate.dayMonthString)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditorSheet(viewModel: viewModel)
            }
        }
        .onAppear {
            viewModel.configure(context: modelContext)
        }
    }

    // MARK: Date navigator (infinite scroll strip)

    private static let stripDayCount = 365

    private var stripDays: [Date] {
        let today = Calendar.current.startOfDay(for: .now)
        return (0..<Self.stripDayCount).reversed().compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: today)
        }
    }

    private var dateNavigator: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(stripDays, id: \.self) { day in
                        let isSelected = Calendar.current.isDate(day, inSameDayAs: viewModel.selectedDate)
                        let isTodayDate = Calendar.current.isDateInToday(day)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedDate = Calendar.current.startOfDay(for: day)
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text(day.weekdayInitial)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(isSelected ? .primary : .secondary)

                                Text(day.dayNumberString)
                                    .font(.title2)
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .foregroundStyle(
                                        isSelected ? .white
                                        : isTodayDate ? Color.red
                                        : .primary
                                    )
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(isSelected ? Color(.label) : .clear)
                                    )
                            }
                            .frame(width: 48)
                        }
                        .buttonStyle(.plain)
                        .id(day)
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                proxy.scrollTo(viewModel.selectedDate, anchor: .trailing)
            }
            .onChange(of: viewModel.selectedDate) { _, newDate in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
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

struct CategoryRow: View {
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
