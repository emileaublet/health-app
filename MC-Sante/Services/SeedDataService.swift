import SwiftData
import Foundation

struct SeedDataService {

    /// Insère les catégories par défaut si elles n'existent pas encore.
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isBuiltIn == true }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (index, cat) in TrackingCategory.defaultCategories.enumerated() {
            let category = TrackingCategory(
                name: cat.0,
                emoji: cat.1,
                dataType: cat.2,
                isBuiltIn: true,
                sortOrder: index
            )
            context.insert(category)
        }
        try? context.save()
    }

    // MARK: - Demo data (10 days)

    /// Generates 10 days of realistic sample data for snapshots and daily entries.
    static func seedDemoData(context: ModelContext) {
        // Check if demo data already exists
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>()
        let existingSnapshots = (try? context.fetch(snapshotDescriptor)) ?? []
        guard existingSnapshots.isEmpty else { return }

        // Ensure categories exist
        seedIfNeeded(context: context)

        // Fetch categories for entries
        let catDescriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isBuiltIn == true },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let categories = (try? context.fetch(catDescriptor)) ?? []

        let calendar = Calendar.current

        for daysAgo in 0..<10 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            let day = calendar.startOfDay(for: date)

            // --- DailySnapshot ---
            let snapshot = DailySnapshot(date: day)

            // Sleep: 5.5–8.5 hours, with realistic stage breakdown
            let totalSleep = Double.random(in: 5.5...8.5)
            snapshot.sleepDurationHours = totalSleep
            snapshot.sleepREMMinutes = totalSleep * Double.random(in: 0.18...0.25) * 60
            snapshot.sleepDeepMinutes = totalSleep * Double.random(in: 0.12...0.20) * 60
            snapshot.sleepCoreMinutes = totalSleep * Double.random(in: 0.45...0.55) * 60

            // Heart
            snapshot.restingHeartRate = Double.random(in: 55...72)
            snapshot.hrvSDNN = Double.random(in: 20...65)
            snapshot.averageHeartRate = Double.random(in: 65...90)

            // Activity
            snapshot.activeCalories = Double.random(in: 150...550)
            snapshot.exerciseMinutes = Double.random(in: 10...60)

            // Blood pressure (some days only)
            if Bool.random() {
                snapshot.systolic = Double.random(in: 110...135)
                snapshot.diastolic = Double.random(in: 65...85)
            }

            // Mood
            snapshot.moodValence = Double.random(in: -0.5...0.8)
            let possibleLabels = LocalizationManager.shared.language == .french
                ? ["calme", "stressé", "fatigué", "énergique", "content", "anxieux"]
                : ["calm", "stressed", "tired", "energetic", "happy", "anxious"]
            let picked = possibleLabels.shuffled().prefix(Int.random(in: 1...3))
            if let data = try? JSONEncoder().encode(Array(picked)) {
                snapshot.moodLabels = String(data: data, encoding: .utf8)
            }

            // Weather
            snapshot.temperatureCelsius = Double.random(in: 8...22)
            snapshot.pressureHPa = Double.random(in: 1005...1030)
            snapshot.humidityPercent = Double.random(in: 40...85)

            snapshot.isComplete = true
            context.insert(snapshot)

            // --- DailyEntry for each category ---
            for cat in categories {
                let entry: DailyEntry
                switch cat.dataType {
                case .counter:
                    entry = DailyEntry(date: day, value: Double(Int.random(in: 0...4)))
                case .boolean:
                    entry = DailyEntry(date: day, value: Bool.random() ? 1 : 0)
                case .scale:
                    entry = DailyEntry(date: day, value: Double(Int.random(in: 1...5)))
                }
                entry.category = cat
                context.insert(entry)
            }
        }

        try? context.save()
    }
}
