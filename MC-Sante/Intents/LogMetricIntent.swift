import AppIntents
import SwiftData
import Foundation

// MARK: - Log Counter Intent

struct LogCounterIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a counter metric"
    static var description: IntentDescription = "Log a counter value (e.g., coffees, glasses of water) for today."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Category name")
    var categoryName: String

    @Parameter(title: "Value", default: 1)
    var value: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(
            for: TrackingCategory.self, DailyEntry.self, DailySnapshot.self, CorrelationResult.self
        )
        let context = ModelContext(container)
        let today = Calendar.current.startOfDay(for: .now)
        let searchName = categoryName

        let descriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == true }
        )
        let categories = (try? context.fetch(descriptor)) ?? []
        guard let category = categories.first(where: {
            $0.name.localizedCaseInsensitiveCompare(searchName) == .orderedSame
        }) else {
            return .result(dialog: "Category \"\(categoryName)\" not found.")
        }

        // Find or create entry for today
        let entryDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == today }
        )
        let entries = (try? context.fetch(entryDescriptor)) ?? []
        let existing = entries.first { $0.category?.id == category.id }

        let clampedValue = Double(max(value, 0))
        if let existing {
            existing.value = clampedValue
        } else {
            let entry = DailyEntry(date: today, value: clampedValue)
            entry.category = category
            context.insert(entry)
        }

        try context.save()
        return .result(dialog: "\(category.emoji) \(category.name): \(value)")
    }
}

// MARK: - Log Boolean Intent

struct LogBooleanIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a yes/no metric"
    static var description: IntentDescription = "Log a yes/no value (e.g., took medication, had sugar) for today."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Category name")
    var categoryName: String

    @Parameter(title: "Yes?", default: true)
    var isYes: Bool

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(
            for: TrackingCategory.self, DailyEntry.self, DailySnapshot.self, CorrelationResult.self
        )
        let context = ModelContext(container)
        let today = Calendar.current.startOfDay(for: .now)
        let searchName = categoryName

        let descriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == true }
        )
        let categories = (try? context.fetch(descriptor)) ?? []
        guard let category = categories.first(where: {
            $0.name.localizedCaseInsensitiveCompare(searchName) == .orderedSame
        }) else {
            return .result(dialog: "Category \"\(categoryName)\" not found.")
        }

        let entryDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == today }
        )
        let entries = (try? context.fetch(entryDescriptor)) ?? []
        let existing = entries.first { $0.category?.id == category.id }

        let val: Double = isYes ? 1 : 0
        if let existing {
            existing.value = val
        } else {
            let entry = DailyEntry(date: today, value: val)
            entry.category = category
            context.insert(entry)
        }

        try context.save()
        let label = isYes ? "Yes" : "No"
        return .result(dialog: "\(category.emoji) \(category.name): \(label)")
    }
}

// MARK: - Log Scale Intent

struct LogScaleIntent: AppIntent {
    static var title: LocalizedStringResource = "Log a scale metric"
    static var description: IntentDescription = "Log a 1-5 scale value (e.g., stress level, energy) for today."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Category name")
    var categoryName: String

    @Parameter(title: "Value (1-5)", inclusiveRange: (1, 5))
    var value: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(
            for: TrackingCategory.self, DailyEntry.self, DailySnapshot.self, CorrelationResult.self
        )
        let context = ModelContext(container)
        let today = Calendar.current.startOfDay(for: .now)
        let searchName = categoryName

        let descriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == true }
        )
        let categories = (try? context.fetch(descriptor)) ?? []
        guard let category = categories.first(where: {
            $0.name.localizedCaseInsensitiveCompare(searchName) == .orderedSame
        }) else {
            return .result(dialog: "Category \"\(categoryName)\" not found.")
        }

        let entryDescriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate { $0.date == today }
        )
        let entries = (try? context.fetch(entryDescriptor)) ?? []
        let existing = entries.first { $0.category?.id == category.id }

        let clamped = Double(min(max(value, 1), 5))
        if let existing {
            existing.value = clamped
        } else {
            let entry = DailyEntry(date: today, value: clamped)
            entry.category = category
            context.insert(entry)
        }

        try context.save()
        return .result(dialog: "\(category.emoji) \(category.name): \(value)/5")
    }
}
