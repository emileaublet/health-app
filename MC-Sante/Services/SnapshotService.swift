import Foundation
import SwiftData

@Observable
final class SnapshotService {
    private let healthKit: HealthKitService
    private let weather: WeatherDataService

    init(healthKit: HealthKitService, weather: WeatherDataService) {
        self.healthKit = healthKit
        self.weather = weather
    }

    /// Construit ou met à jour le DailySnapshot pour la date donnée.
    @MainActor
    func buildSnapshot(for date: Date, context: ModelContext) async {
        let startOfDay = Calendar.current.startOfDay(for: date)

        // Récupérer ou créer le snapshot
        let descriptor = FetchDescriptor<DailySnapshot>(
            predicate: #Predicate { $0.date == startOfDay }
        )
        let existing = (try? context.fetch(descriptor)) ?? []
        let snapshot: DailySnapshot
        if let found = existing.first {
            snapshot = found
        } else {
            snapshot = DailySnapshot(date: date)
            context.insert(snapshot)
        }

        // --- Sommeil ---
        if let sleep = await healthKit.fetchSleepData(for: date) {
            snapshot.sleepDurationHours = sleep.totalHours
            snapshot.sleepREMMinutes    = sleep.remMinutes
            snapshot.sleepDeepMinutes  = sleep.deepMinutes
            snapshot.sleepCoreMinutes  = sleep.coreMinutes
        }

        // --- Cardiaque ---
        if let heart = await healthKit.fetchHeartData(for: date) {
            snapshot.restingHeartRate  = heart.resting > 0 ? heart.resting : nil
            snapshot.hrvSDNN           = heart.hrv > 0 ? heart.hrv : nil
            snapshot.averageHeartRate  = heart.average > 0 ? heart.average : nil
        }

        // --- Activité ---
        if let activity = await healthKit.fetchActivityData(for: date) {
            snapshot.activeCalories  = activity.calories > 0 ? activity.calories : nil
            snapshot.exerciseMinutes = activity.minutes > 0 ? activity.minutes : nil
        }

        // --- Cycle ---
        snapshot.menstrualFlowRaw = await healthKit.fetchMenstrualFlow(for: date)

        // --- Tension ---
        if let bp = await healthKit.fetchBloodPressure(for: date) {
            snapshot.systolic  = bp.systolic
            snapshot.diastolic = bp.diastolic
        }

        // --- Humeur ---
        if let mood = await healthKit.fetchStateOfMind(for: date) {
            snapshot.moodValence = mood.valence
            if let data = try? JSONEncoder().encode(mood.labels) {
                snapshot.moodLabels = String(data: data, encoding: .utf8)
            }
        }

        // --- Météo ---
        if let w = await weather.fetchWeather() {
            snapshot.temperatureCelsius = w.temperatureCelsius
            snapshot.pressureHPa        = w.pressureHPa
            snapshot.humidityPercent    = w.humidityPercent
        }

        snapshot.isComplete = true
        try? context.save()
    }

    /// Lance le snapshot pour today + les 6 derniers jours (rattrapage).
    @MainActor
    func buildRecentSnapshots(context: ModelContext) async {
        for daysAgo in 0..<7 {
            guard let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now) else { continue }
            await buildSnapshot(for: date, context: context)
        }
    }
}
