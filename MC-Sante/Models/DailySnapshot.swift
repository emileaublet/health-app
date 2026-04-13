import SwiftData
import Foundation

@Model
final class DailySnapshot {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var date: Date  // un seul snapshot par jour

    // HealthKit — Sommeil
    var sleepDurationHours: Double?
    var sleepREMMinutes: Double?
    var sleepDeepMinutes: Double?
    var sleepCoreMinutes: Double?

    // HealthKit — Cardiaque
    var restingHeartRate: Double?
    var hrvSDNN: Double?
    var averageHeartRate: Double?

    // HealthKit — Activité
    var activeCalories: Double?
    var exerciseMinutes: Double?
    var stepCount: Double?
    var walkingRunningDistanceKilometers: Double?

    // HealthKit — Cycle
    var menstrualFlowRaw: Int?  // 0=none, 1=light, 2=medium, 3=heavy

    // HealthKit — Tension
    var systolic: Double?
    var diastolic: Double?

    // HealthKit — Humeur (iOS 18+)
    var moodValence: Double?   // -1.0 à +1.0
    var moodLabels: String?    // JSON array de labels ex: ["stressed","tired"]

    // Météo
    var temperatureCelsius: Double?
    var pressureHPa: Double?
    var humidityPercent: Double?

    // Méta
    var isComplete: Bool       // toutes les sources ont répondu

    init(date: Date) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.isComplete = false
    }
}

// MARK: - Completeness helpers

extension DailySnapshot {
    /// Nombre de métriques HealthKit renseignées
    var healthDataCount: Int {
        [sleepDurationHours, restingHeartRate, activeCalories, moodValence]
            .compactMap { $0 }.count
    }

    var hasWeatherData: Bool {
        temperatureCelsius != nil && pressureHPa != nil
    }

    var decodedMoodLabels: [String] {
        guard let raw = moodLabels,
              let data = raw.data(using: .utf8),
              let labels = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return labels
    }

    /// Double cast of menstrualFlowRaw for sparkline bar charts.
    var menstrualFlowValue: Double? {
        menstrualFlowRaw.map { Double($0) }
    }
}
