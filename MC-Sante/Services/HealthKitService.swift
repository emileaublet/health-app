import Foundation
import HealthKit

// MARK: - Data transfer structs

struct SleepData {
    let totalHours: Double
    let remMinutes: Double
    let deepMinutes: Double
    let coreMinutes: Double
}

struct HeartData {
    let resting: Double
    let hrv: Double
    let average: Double
}

struct ActivityData {
    let calories: Double
    let minutes: Double
    let steps: Double
    let distanceKilometers: Double
}

struct BloodPressureData {
    let systolic: Double
    let diastolic: Double
}

struct StateOfMindData {
    let valence: Double
    let labels: [String]
}

// MARK: - HealthKitService

@Observable
final class HealthKitService {
    private let healthStore = HKHealthStore()

    private(set) var isAuthorized = false
    private(set) var authorizationError: Error?

    private static let typesToRead: Set<HKObjectType> = [
        HKCategoryType(.sleepAnalysis),
        HKQuantityType(.heartRate),
        HKQuantityType(.restingHeartRate),
        HKQuantityType(.heartRateVariabilitySDNN),
        HKQuantityType(.activeEnergyBurned),
        HKQuantityType(.appleExerciseTime),
        HKQuantityType(.stepCount),
        HKQuantityType(.distanceWalkingRunning),
        HKCategoryType(.menstrualFlow),
        HKQuantityType(.bloodPressureSystolic),
        HKQuantityType(.bloodPressureDiastolic),
    ]

    private static let typesToWrite: Set<HKSampleType> = [
        HKObjectType.stateOfMindType(),
    ]

    // MARK: Authorization

    /// Check existing authorization status without prompting the user.
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return
        }
        // HealthKit doesn't expose a single "all authorized" check for read types
        // (read status is always .sharingDenied to protect privacy).
        // Check write authorization for State of Mind as a proxy — if the user
        // has gone through the authorization flow, this will be .authorized.
        let writeStatus = healthStore.authorizationStatus(for: HKObjectType.stateOfMindType())
        isAuthorized = writeStatus == .sharingAuthorized
    }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                authorizationError = HKError(.errorHealthDataUnavailable)
                isAuthorized = false
            }
            return
        }

        do {
            try await healthStore.requestAuthorization(toShare: Self.typesToWrite, read: Self.typesToRead)
            await MainActor.run {
                checkAuthorizationStatus()
            }
        } catch {
            await MainActor.run {
                authorizationError = error
                isAuthorized = false
            }
        }
    }

    // MARK: Sleep

    func fetchSleepData(for date: Date) async -> SleepData? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let cal = Calendar.current

        // Window: 18h the evening before → 12h of the given day (captures full night)
        guard
            let previousEvening = cal.date(
                bySettingHour: 18, minute: 0, second: 0,
                of: date.addingTimeInterval(-86400)
            ),
            let sleepEnd = cal.date(bySettingHour: 12, minute: 0, second: 0, of: date)
        else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: previousEvening, end: sleepEnd)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)]
        )

        guard let samples = try? await descriptor.result(for: healthStore),
              !samples.isEmpty else { return nil }

        var totalSleep: TimeInterval = 0
        var remMinutes: TimeInterval = 0
        var deepMinutes: TimeInterval = 0
        var coreMinutes: TimeInterval = 0

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)
            switch sample.value {
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remMinutes += duration
                totalSleep += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepMinutes += duration
                totalSleep += duration
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                coreMinutes += duration
                totalSleep += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                totalSleep += duration
            default:
                break // inBed, awake — ignored
            }
        }

        guard totalSleep > 0 else { return nil }

        return SleepData(
            totalHours: totalSleep / 3600,
            remMinutes: remMinutes / 60,
            deepMinutes: deepMinutes / 60,
            coreMinutes: coreMinutes / 60
        )
    }

    // MARK: Heart Rate / HRV

    func fetchHeartData(for date: Date) async -> HeartData? {
        async let resting = fetchLatestQuantity(.restingHeartRate, for: date, unit: .count().unitDivided(by: .minute()))
        async let hrv     = fetchLatestQuantity(.heartRateVariabilitySDNN, for: date, unit: .secondUnit(with: .milli))
        async let avg     = fetchAverageQuantity(.heartRate, for: date, unit: .count().unitDivided(by: .minute()))

        let (r, h, a) = await (resting, hrv, avg)
        guard r != nil || h != nil || a != nil else { return nil }

        return HeartData(resting: r ?? 0, hrv: h ?? 0, average: a ?? 0)
    }

    // MARK: Activity

    func fetchActivityData(for date: Date) async -> ActivityData? {
        async let calories = fetchSumQuantity(.activeEnergyBurned, for: date, unit: .kilocalorie())
        async let minutes  = fetchSumQuantity(.appleExerciseTime,  for: date, unit: .minute())
        async let steps    = fetchSumQuantity(.stepCount, for: date, unit: .count())
        async let distance = fetchSumQuantity(.distanceWalkingRunning, for: date, unit: .meter())

        let (c, m, s, d) = await (calories, minutes, steps, distance)
        guard c != nil || m != nil || s != nil || d != nil else { return nil }

        return ActivityData(
            calories: c ?? 0,
            minutes: m ?? 0,
            steps: s ?? 0,
            distanceKilometers: (d ?? 0) / 1000
        )
    }

    // MARK: Menstrual flow

    func fetchMenstrualFlow(for date: Date) async -> Int? {
        let type = HKCategoryType(.menstrualFlow)
        let predicate = dayPredicate(for: date)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        guard let samples = try? await descriptor.result(for: healthStore),
              let sample = samples.first else { return nil }
        return sample.value
    }

    // MARK: Blood Pressure

    func fetchBloodPressure(for date: Date) async -> BloodPressureData? {
        let correlationType = HKCorrelationType(.bloodPressure)
        let predicate = dayPredicate(for: date)

        return await withCheckedContinuation { continuation in
            let query = HKCorrelationQuery(
                type: correlationType,
                predicate: predicate,
                samplePredicates: nil
            ) { _, results, _ in
                guard let correlation = results?.first else {
                    continuation.resume(returning: nil)
                    return
                }

                let systolicType = HKQuantityType(.bloodPressureSystolic)
                let diastolicType = HKQuantityType(.bloodPressureDiastolic)
                let unit = HKUnit.millimeterOfMercury()

                let systolic = correlation.objects(for: systolicType)
                    .compactMap { ($0 as? HKQuantitySample)?.quantity.doubleValue(for: unit) }
                    .first
                let diastolic = correlation.objects(for: diastolicType)
                    .compactMap { ($0 as? HKQuantitySample)?.quantity.doubleValue(for: unit) }
                    .first

                guard let s = systolic, let d = diastolic else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: BloodPressureData(systolic: s, diastolic: d))
            }
            healthStore.execute(query)
        }
    }

    // MARK: State of Mind (iOS 18+)

    func fetchStateOfMind(for date: Date) async -> StateOfMindData? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else { return nil }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.stateOfMind(predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        guard let results = try? await descriptor.result(for: healthStore),
              let sample = results.first else { return nil }

        let labels = sample.labels.map { $0.rawValue.description }
        return StateOfMindData(valence: sample.valence, labels: labels)
    }

    // MARK: Write State of Mind

    func writeStateOfMind(valence: Double, kind: HKStateOfMind.Kind, date: Date) async throws {
        let sample = HKStateOfMind(
            date: date,
            kind: kind,
            valence: valence,
            labels: [],
            associations: []
        )
        try await healthStore.save(sample)
    }

    // MARK: Private helpers

    private func dayPredicate(for date: Date) -> NSPredicate {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        return HKQuery.predicateForSamples(withStart: start, end: end)
    }

    private func fetchLatestQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        for date: Date,
        unit: HKUnit
    ) async -> Double? {
        let type = HKQuantityType(identifier)
        let predicate = dayPredicate(for: date)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)],
            limit: 1
        )
        guard let results = try? await descriptor.result(for: healthStore),
              let sample = results.first else { return nil }
        return sample.quantity.doubleValue(for: unit)
    }

    private func fetchSumQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        for date: Date,
        unit: HKUnit
    ) async -> Double? {
        let type = HKQuantityType(identifier)
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: predicate),
            options: .cumulativeSum
        )
        guard let statistics = try? await descriptor.result(for: healthStore),
              let sum = statistics.sumQuantity() else { return nil }
        return sum.doubleValue(for: unit)
    }

    private func fetchAverageQuantity(
        _ identifier: HKQuantityTypeIdentifier,
        for date: Date,
        unit: HKUnit
    ) async -> Double? {
        let type = HKQuantityType(identifier)
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: type, predicate: predicate),
            options: .discreteAverage
        )
        guard let statistics = try? await descriptor.result(for: healthStore),
              let avg = statistics.averageQuantity() else { return nil }
        return avg.doubleValue(for: unit)
    }
}
