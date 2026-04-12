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
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate)!
        loadEntriesForCurrentDate()
    }

    func goToNextDay() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
        guard tomorrow <= Calendar.current.startOfDay(for: .now) else { return }
        selectedDate = tomorrow
        loadEntriesForCurrentDate()
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var canGoForward: Bool {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate)!
        return tomorrow <= Calendar.current.startOfDay(for: .now)
    }

    // MARK: Data loading

    func loadCategories() {
        guard let context else { return }
        var descriptor = FetchDescriptor<TrackingCategory>(
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
