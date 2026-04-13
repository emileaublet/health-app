import Foundation
import SwiftData

@Observable
final class LogViewModel {
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    var categories: [TrackingCategory] = []
    var entriesForDate: [UUID: DailyEntry] = [:]  // categoryId → entry
    var dayNote: String = ""
    var isSaving = false

    private var context: ModelContext?

    func configure(context: ModelContext) {
        self.context = context
        loadCategories()
    }

    // MARK: Navigation

    func goToPreviousDay() {
        guard let prev = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) else { return }
        selectedDate = prev
        loadEntriesForCurrentDate()
    }

    func goToNextDay() {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return }
        guard tomorrow <= Calendar.current.startOfDay(for: .now) else { return }
        selectedDate = tomorrow
        loadEntriesForCurrentDate()
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var canGoForward: Bool {
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) else { return false }
        return tomorrow <= Calendar.current.startOfDay(for: .now)
    }

    // MARK: Data loading

    func loadCategories() {
        guard let context else { return }
        let descriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        categories = (try? context.fetch(descriptor)) ?? []
        loadEntriesForCurrentDate()
    }

    func loadEntriesForCurrentDate() {
        guard let context else { return }
        let date = selectedDate
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == date }
        )
        let entries = (try? context.fetch(descriptor)) ?? []
        entriesForDate = Dictionary(
            uniqueKeysWithValues: entries.compactMap { entry in
                guard let catId = entry.category?.id else { return nil }
                return (catId, entry)
            }
        )
    }

    // MARK: Value mutation (auto-save)

    func setValue(_ value: Double, for category: TrackingCategory) {
        guard let context else { return }
        if let existing = entriesForDate[category.id] {
            existing.value = value
        } else {
            let entry = DailyEntry(date: selectedDate, value: value)
            entry.category = category
            context.insert(entry)
            entriesForDate[category.id] = entry
        }
        try? context.save()
    }

    func currentValue(for category: TrackingCategory) -> Double {
        entriesForDate[category.id]?.value ?? defaultValue(for: category.dataType)
    }

    func setDayNote(_ note: String) {
        guard let context else { return }
        let text = note.trimmingCharacters(in: .whitespaces)

        // Prefer updating an entry that already carries a note
        if let existing = entriesForDate.values.first(where: { $0.note != nil }) {
            existing.note = text.isEmpty ? nil : text
            try? context.save()
            return
        }
        // Fall back to any existing entry for this day
        if let first = entriesForDate.values.first {
            first.note = text.isEmpty ? nil : text
            try? context.save()
            return
        }
        // No entries yet — create a note-only entry (category = nil)
        if !text.isEmpty {
            let entry = DailyEntry(date: selectedDate, value: 0, note: text)
            context.insert(entry)
            try? context.save()
        }
    }

    private func defaultValue(for type: MetricDataType) -> Double {
        switch type {
        case .counter: return 0
        case .boolean: return 0
        case .scale:   return 0  // 0 = non renseigné
        }
    }

    // MARK: Category management

    func createCategory(name: String, emoji: String, dataType: MetricDataType) {
        guard let context else { return }
        let maxOrder = categories.map(\.sortOrder).max() ?? 0
        let category = TrackingCategory(
            name: name, emoji: emoji,
            dataType: dataType, isBuiltIn: false,
            sortOrder: maxOrder + 1
        )
        context.insert(category)
        try? context.save()
        loadCategories()
    }

    func archiveCategory(_ category: TrackingCategory) {
        category.isActive = false
        try? context?.save()
        loadCategories()
    }

    func reactivateCategory(_ category: TrackingCategory) {
        category.isActive = true
        try? context?.save()
        loadCategories()
    }

    func updateSortOrder(_ categories: [TrackingCategory]) {
        for (index, category) in categories.enumerated() {
            category.sortOrder = index
        }
        try? context?.save()
    }
}
