import XCTest
import SwiftData
@testable import MC_Sante

@MainActor
final class SwiftDataModelTests: XCTestCase {

    private var container: ModelContainer!
    private var context: ModelContext!

    override func setUp() async throws {
        try await super.setUp()
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: TrackingCategory.self, DailyEntry.self,
                DailySnapshot.self, CorrelationResult.self,
            configurations: config
        )
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        context = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - TrackingCategory

    func test_trackingCategory_init_setsDefaults() {
        let cat = TrackingCategory(name: "Café", emoji: "☕", dataType: .counter)
        XCTAssertEqual(cat.name, "Café")
        XCTAssertEqual(cat.emoji, "☕")
        XCTAssertEqual(cat.dataType, .counter)
        XCTAssertTrue(cat.isActive)
        XCTAssertFalse(cat.isBuiltIn)
        XCTAssertEqual(cat.sortOrder, 0)
    }

    func test_trackingCategory_builtIn_flag() {
        let cat = TrackingCategory(
            name: "Stress", emoji: "😰", dataType: .scale, isBuiltIn: true)
        XCTAssertTrue(cat.isBuiltIn)
    }

    func test_trackingCategory_persistAndFetch() throws {
        let cat = TrackingCategory(name: "Thé", emoji: "🍵", dataType: .counter)
        context.insert(cat)
        try context.save()

        let descriptor = FetchDescriptor<TrackingCategory>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].name, "Thé")
        XCTAssertEqual(fetched[0].emoji, "🍵")
    }

    func test_trackingCategory_archive_setsInactive() throws {
        let cat = TrackingCategory(name: "Alcool", emoji: "🍷", dataType: .counter)
        context.insert(cat)
        try context.save()

        cat.isActive = false
        try context.save()

        let activeDescriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == true })
        let archivedDescriptor = FetchDescriptor<TrackingCategory>(
            predicate: #Predicate { $0.isActive == false })
        XCTAssertTrue(try context.fetch(activeDescriptor).isEmpty)
        XCTAssertEqual(try context.fetch(archivedDescriptor).count, 1)
    }

    func test_trackingCategory_defaultCategories_haveExpectedCount() {
        XCTAssertEqual(TrackingCategory.defaultCategories.count, 5)
    }

    func test_metricDataType_allCases_has3Values() {
        XCTAssertEqual(MetricDataType.allCases.count, 3)
    }

    func test_metricDataType_labels_areNonEmpty() {
        for type in MetricDataType.allCases {
            XCTAssertFalse(type.label.isEmpty)
        }
    }

    // MARK: - DailyEntry

    func test_dailyEntry_dateNormalizedToMidnight() {
        let noon = Calendar.current.date(
            bySettingHour: 12, minute: 30, second: 45, of: Date())!
        let entry = DailyEntry(date: noon, value: 3.0)
        let comps = Calendar.current.dateComponents([.hour, .minute, .second], from: entry.date)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
        XCTAssertEqual(comps.second, 0)
    }

    func test_dailyEntry_noteIsNilByDefault() {
        let entry = DailyEntry(date: Date(), value: 1.0)
        XCTAssertNil(entry.note)
    }

    func test_dailyEntry_noteCanBeSet() {
        let entry = DailyEntry(date: Date(), value: 1.0, note: "Bonne journée")
        XCTAssertEqual(entry.note, "Bonne journée")
    }

    func test_dailyEntry_persistWithCategory() throws {
        let cat = TrackingCategory(name: "Café", emoji: "☕", dataType: .counter)
        let entry = DailyEntry(date: Date(), value: 2.0)
        entry.category = cat
        context.insert(cat)
        context.insert(entry)
        try context.save()

        let descriptor = FetchDescriptor<DailyEntry>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].value, 2.0)
        XCTAssertEqual(fetched[0].category?.name, "Café")
    }

    func test_dailyEntry_cascadeDelete_whenCategoryDeleted() throws {
        let cat = TrackingCategory(name: "Test", emoji: "🔥", dataType: .boolean)
        let entry = DailyEntry(date: Date(), value: 1.0)
        entry.category = cat
        context.insert(cat)
        context.insert(entry)
        try context.save()

        context.delete(cat)
        try context.save()

        let entryDescriptor = FetchDescriptor<DailyEntry>()
        let remaining = try context.fetch(entryDescriptor)
        XCTAssertTrue(remaining.isEmpty,
            "DailyEntry should be cascade-deleted when its category is removed")
    }

    // MARK: - DailySnapshot

    func test_dailySnapshot_init_setsDateToMidnight() {
        let noon = Calendar.current.date(
            bySettingHour: 14, minute: 30, second: 0, of: Date())!
        let snapshot = DailySnapshot(date: noon)
        let comps = Calendar.current.dateComponents([.hour, .minute], from: snapshot.date)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
    }

    func test_dailySnapshot_isCompleteDefaultsFalse() {
        let snapshot = DailySnapshot(date: Date())
        XCTAssertFalse(snapshot.isComplete)
    }

    func test_dailySnapshot_allOptionalFieldsDefaultNil() {
        let snapshot = DailySnapshot(date: Date())
        XCTAssertNil(snapshot.sleepDurationHours)
        XCTAssertNil(snapshot.restingHeartRate)
        XCTAssertNil(snapshot.hrvSDNN)
        XCTAssertNil(snapshot.activeCalories)
        XCTAssertNil(snapshot.moodValence)
        XCTAssertNil(snapshot.temperatureCelsius)
        XCTAssertNil(snapshot.pressureHPa)
    }

    func test_dailySnapshot_healthDataCount_countsNonNilFields() {
        let snapshot = DailySnapshot(date: Date())
        context.insert(snapshot)
        XCTAssertEqual(snapshot.healthDataCount, 0)
        snapshot.sleepDurationHours = 7.0
        XCTAssertEqual(snapshot.healthDataCount, 1)
        snapshot.restingHeartRate = 62.0
        XCTAssertEqual(snapshot.healthDataCount, 2)
        snapshot.activeCalories = 400.0
        XCTAssertEqual(snapshot.healthDataCount, 3)
        snapshot.moodValence = 0.5
        XCTAssertEqual(snapshot.healthDataCount, 4)
    }

    func test_dailySnapshot_hasWeatherData_requiresBothFields() {
        let snapshot = DailySnapshot(date: Date())
        context.insert(snapshot)
        XCTAssertFalse(snapshot.hasWeatherData)
        snapshot.temperatureCelsius = 22.0
        XCTAssertFalse(snapshot.hasWeatherData)   // pressureHPa still nil
        snapshot.pressureHPa = 1013.0
        XCTAssertTrue(snapshot.hasWeatherData)
    }

    func test_dailySnapshot_decodedMoodLabels_parsesValidJSON() {
        let snapshot = DailySnapshot(date: Date())
        context.insert(snapshot)
        snapshot.moodLabels = "[\"stressed\",\"tired\"]"
        XCTAssertEqual(snapshot.decodedMoodLabels, ["stressed", "tired"])
    }

    func test_dailySnapshot_decodedMoodLabels_nilReturnsEmpty() {
        let snapshot = DailySnapshot(date: Date())
        XCTAssertEqual(snapshot.decodedMoodLabels, [])
    }

    func test_dailySnapshot_decodedMoodLabels_invalidJSONReturnsEmpty() {
        let snapshot = DailySnapshot(date: Date())
        snapshot.moodLabels = "not valid json"
        XCTAssertEqual(snapshot.decodedMoodLabels, [])
    }

    func test_dailySnapshot_persistAndFetch() throws {
        let snapshot = DailySnapshot(date: Date())
        snapshot.sleepDurationHours = 7.5
        snapshot.isComplete = true
        context.insert(snapshot)
        try context.save()

        let descriptor = FetchDescriptor<DailySnapshot>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].sleepDurationHours, 7.5)
        XCTAssertTrue(fetched[0].isComplete)
    }

    // MARK: - CorrelationResult

    func test_correlationResult_strengthComputedFromR() {
        let weak     = makeResult(r: 0.40)
        let moderate = makeResult(r: 0.60)
        let strong   = makeResult(r: 0.80)
        XCTAssertEqual(weak.strength,     .weak)
        XCTAssertEqual(moderate.strength, .moderate)
        XCTAssertEqual(strong.strength,   .strong)
    }

    func test_correlationResult_negativeR_strengthUsesAbsoluteValue() {
        XCTAssertEqual(makeResult(r: -0.80).strength, .strong)
        XCTAssertEqual(makeResult(r: -0.60).strength, .moderate)
        XCTAssertEqual(makeResult(r: -0.40).strength, .weak)
    }

    func test_correlationResult_isPositive_reflectsSign() {
        XCTAssertTrue(makeResult(r: 0.7).isPositive)
        XCTAssertFalse(makeResult(r: -0.7).isPositive)
    }

    func test_correlationStrength_labels_areNonEmpty() {
        XCTAssertFalse(CorrelationStrength.weak.label.isEmpty)
        XCTAssertFalse(CorrelationStrength.moderate.label.isEmpty)
        XCTAssertFalse(CorrelationStrength.strong.label.isEmpty)
    }

    func test_correlationResult_persistAndFetch() throws {
        let result = makeResult(r: 0.75)
        context.insert(result)
        try context.save()

        let descriptor = FetchDescriptor<CorrelationResult>()
        let fetched = try context.fetch(descriptor)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched[0].pearsonR, 0.75, accuracy: 1e-10)
    }

    // MARK: - Helper

    private func makeResult(r: Double) -> CorrelationResult {
        CorrelationResult(
            metricA: "A", metricB: "B",
            pearsonR: r, sampleSize: 14, lagDays: 0, windowDays: 14,
            insightText: "Test insight"
        )
    }
}
