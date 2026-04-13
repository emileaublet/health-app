import Foundation
import SwiftData

@Observable
final class LogViewModel {
    var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    var categories: [TrackingCategory] = []
    var entriesForDate: [UUID: DailyEntry] = [:]  // categoryId → entry
    var dayNote: String = ""
    var isSaving = false

    // CalendarStrip: dates that have logged entries
    var datesWithEntries: Set<Date> = []

    // Error handling
    var showSaveError: Bool = false

    private var context: ModelContext?

    func configure(context: ModelContext) {
        self.context = context
        loadCategories()
        loadDatesWithEntries()
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
        let clamped = Self.clampValue(value, for: category.dataType)
        if let existing = entriesForDate[category.id] {
            existing.value = clamped
        } else {
            let entry = DailyEntry(date: selectedDate, value: clamped)
            entry.category = category
            context.insert(entry)
            entriesForDate[category.id] = entry
        }
        saveContext()
        // Update CalendarStrip dots
        if clamped > 0 {
            datesWithEntries.insert(selectedDate)
        }
    }

    /// Clamps a value to the valid range for the given data type.
    private static func clampValue(_ value: Double, for dataType: MetricDataType) -> Double {
        switch dataType {
        case .scale:   return min(max(value, 0), 5)  // 0 = unset, 1-5 valid
        case .boolean: return value >= 1 ? 1 : 0
        case .counter: return max(value, 0)
        }
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
            saveContext()
            return
        }
        // Fall back to any existing entry for this day
        if let first = entriesForDate.values.first {
            first.note = text.isEmpty ? nil : text
            saveContext()
            return
        }
        // No entries yet — create a note-only entry (category = nil)
        if !text.isEmpty {
            let entry = DailyEntry(date: selectedDate, value: 0, note: text)
            context.insert(entry)
            saveContext()
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
        saveContext()
        loadCategories()
    }

    func archiveCategory(_ category: TrackingCategory) {
        category.isActive = false
        saveContext()
        loadCategories()
    }

    func reactivateCategory(_ category: TrackingCategory) {
        category.isActive = true
        saveContext()
        loadCategories()
    }

    func updateSortOrder(_ categories: [TrackingCategory]) {
        for (index, category) in categories.enumerated() {
            category.sortOrder = index
        }
        saveContext()
    }

    func onDateChanged() {
        loadEntriesForCurrentDate()
    }

    // MARK: Dates with entries (for CalendarStrip)

    func loadDatesWithEntries() {
        guard let context else { return }
        let descriptor = FetchDescriptor<DailyEntry>()
        let entries = (try? context.fetch(descriptor)) ?? []
        datesWithEntries = Set(entries.compactMap { entry in
            entry.value > 0 ? entry.date : nil
        })
    }

    // MARK: Safe save

    private func saveContext() {
        do {
            try context?.save()
        } catch {
            showSaveError = true
        }
    }
}
