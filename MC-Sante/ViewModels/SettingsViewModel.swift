import Foundation
import SwiftData

@Observable
final class SettingsViewModel {
    var reminderEnabled: Bool = true
    var reminderHour: Int = 21
    var reminderMinute: Int = 0
    var archivedCategories: [TrackingCategory] = []

    private let notificationService: NotificationService
    private var context: ModelContext?

    init(notificationService: NotificationService) {
        self.notificationService = notificationService
        // Restore persisted settings
        reminderEnabled = UserDefaults.standard.object(forKey: "reminderEnabled") as? Bool ?? true
        reminderHour    = UserDefaults.standard.object(forKey: "reminderHour")    as? Int ?? 21
        reminderMinute  = UserDefaults.standard.object(forKey: "reminderMinute")  as? Int ?? 0
    }

    func configure(context: ModelContext) {
        self.context = context
        loadArchivedCategories()
    }

    // MARK: Reminder

    @MainActor
    func applyReminderSettings() async {
        UserDefaults.standard.set(reminderEnabled, forKey: "reminderEnabled")
        UserDefaults.standard.set(reminderHour,    forKey: "reminderHour")
        UserDefaults.standard.set(reminderMinute,  forKey: "reminderMinute")

        if reminderEnabled {
            await notificationService.scheduleDailyReminder(
                hour: reminderHour,
                minute: reminderMinute
            )
        } else {
            notificationService.cancelDailyReminder()
        }
    }

    // MARK: Archived categories

    func loadArchivedCategories() {
        guard let context else { return }
        let descriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == false },
            sortBy: [SortDescriptor(\.name)]
        )
        archivedCategories = (try? context.fetch(descriptor)) ?? []
    }

    func reactivate(_ category: TrackingCategory) {
        category.isActive = true
        try? context?.save()
        loadArchivedCategories()
    }

    // MARK: Export CSV

    func exportCSV(context: ModelContext) -> URL? {
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date)]
        )
        let snapshots = (try? context.fetch(snapshotDescriptor)) ?? []

        let entryDescriptor = FetchDescriptor<DailyEntry>()
        let entries = (try? context.fetch(entryDescriptor)) ?? []

        let categoryDescriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let categories = (try? context.fetch(categoryDescriptor)) ?? []

        return CSVExporter.export(
            snapshots: snapshots,
            entries: entries,
            categories: categories
        )
    }
}

// MARK: - CSV Exporter

enum CSVExporter {
    static func export(
        snapshots: [DailySnapshot],
        entries: [DailyEntry],
        categories: [TrackingCategory]
    ) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        var lines: [String] = []
        let isFrench = LocalizationManager.shared.language == .french
        var header = isFrench
            ? "Date,Sommeil (h),REM (min),Deep (min),FC repos,HRV,Calories,Exercice (min),Pas,Distance (km),Humeur (valence),Temp (°C),Pression (hPa),Humidité (%)"
            : "Date,Sleep (h),REM (min),Deep (min),Resting HR,HRV,Calories,Exercise (min),Steps,Distance (km),Mood (valence),Temp (°C),Pressure (hPa),Humidity (%)"
        for cat in categories { header += ",\(cat.name)" }
        lines.append(header)

        for snapshot in snapshots {
            var row = formatter.string(from: snapshot.date)
            row += ",\(snapshot.sleepDurationHours.csvValue)"
            row += ",\(snapshot.sleepREMMinutes.csvValue)"
            row += ",\(snapshot.sleepDeepMinutes.csvValue)"
            row += ",\(snapshot.restingHeartRate.csvValue)"
            row += ",\(snapshot.hrvSDNN.csvValue)"
            row += ",\(snapshot.activeCalories.csvValue)"
            row += ",\(snapshot.exerciseMinutes.csvValue)"
            row += ",\(snapshot.stepCount.csvValue)"
            row += ",\(snapshot.walkingRunningDistanceKilometers.csvValue)"
            row += ",\(snapshot.moodValence.csvValue)"
            row += ",\(snapshot.temperatureCelsius.csvValue)"
            row += ",\(snapshot.pressureHPa.csvValue)"
            row += ",\(snapshot.humidityPercent.csvValue)"

            for cat in categories {
                let entry = entries.first {
                    $0.category?.id == cat.id && $0.date == snapshot.date
                }
                row += ",\(entry?.value.csvValue ?? "")"
            }
            lines.append(row)
        }

        let csv = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("mc-sante-export.csv")
        guard (try? csv.write(to: url, atomically: true, encoding: .utf8)) != nil else {
            return nil
        }
        return url
    }
}

private extension Optional where Wrapped == Double {
    var csvValue: String {
        guard let v = self else { return "" }
        return String(format: "%.2f", v)
    }
}

private extension Double {
    var csvValue: String { String(format: "%.2f", self) }
}
