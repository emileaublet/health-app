import XCTest
@testable import MC_Sante

final class CSVExporterTests: XCTestCase {

    // MARK: - Header

    func test_export_emptyData_producesExactlyOneLineHeader() {
        guard let url = CSVExporter.export(snapshots: [], entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        let lines = csvLines(at: url)
        XCTAssertEqual(lines.count, 1)
    }

    func test_export_headerStartsWithDate() {
        guard let url = CSVExporter.export(snapshots: [], entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        XCTAssertTrue(csvLines(at: url)[0].hasPrefix("Date"))
    }

    func test_export_headerContainsCoreHealthColumns() {
        guard let url = CSVExporter.export(snapshots: [], entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        let header = csvLines(at: url)[0]
        XCTAssertTrue(header.contains("Sommeil (h)"),     "Missing sleep column")
        XCTAssertTrue(header.contains("REM (min)"),       "Missing REM column")
        XCTAssertTrue(header.contains("Deep (min)"),      "Missing Deep column")
        XCTAssertTrue(header.contains("FC repos"),        "Missing resting HR column")
        XCTAssertTrue(header.contains("HRV"),             "Missing HRV column")
        XCTAssertTrue(header.contains("Calories"),        "Missing calories column")
        XCTAssertTrue(header.contains("Humeur (valence)"), "Missing mood column")
    }

    func test_export_headerContainsWeatherColumns() {
        guard let url = CSVExporter.export(snapshots: [], entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        let header = csvLines(at: url)[0]
        XCTAssertTrue(header.contains("Temp"),     "Missing temperature column")
        XCTAssertTrue(header.contains("Pression"), "Missing pressure column")
        XCTAssertTrue(header.contains("Humidité"), "Missing humidity column")
    }

    func test_export_categoryAppendedToHeader() {
        let cat = TrackingCategory(name: "Café", emoji: "☕", dataType: .counter)
        guard let url = CSVExporter.export(snapshots: [], entries: [], categories: [cat]) else {
            return XCTFail("Export returned nil URL")
        }
        XCTAssertTrue(csvLines(at: url)[0].contains("Café"))
    }

    func test_export_multipleCategories_allInHeader() {
        let cats = [
            TrackingCategory(name: "Café",   emoji: "☕", dataType: .counter),
            TrackingCategory(name: "Stress", emoji: "😰", dataType: .scale),
        ]
        guard let url = CSVExporter.export(snapshots: [], entries: [], categories: cats) else {
            return XCTFail("Export returned nil URL")
        }
        let header = csvLines(at: url)[0]
        XCTAssertTrue(header.contains("Café"))
        XCTAssertTrue(header.contains("Stress"))
    }

    // MARK: - Data rows

    func test_export_oneSnapshot_producesTwoLines() {
        let snapshot = DailySnapshot(date: Date())
        guard let url = CSVExporter.export(snapshots: [snapshot], entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        XCTAssertEqual(csvLines(at: url).count, 2)
    }

    func test_export_nSnapshots_producesNPlusOneLines() {
        let snapshots = (0..<5).map { i in
            DailySnapshot(date: Calendar.current.date(
                byAdding: .day, value: -i, to: Date())!)
        }
        guard let url = CSVExporter.export(snapshots: snapshots, entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        XCTAssertEqual(csvLines(at: url).count, 6)  // header + 5 rows
    }

    func test_export_dataRow_containsFormattedSleepValue() {
        let snapshot = DailySnapshot(date: Date())
        snapshot.sleepDurationHours = 7.5
        guard let url = CSVExporter.export(snapshots: [snapshot], entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        XCTAssertTrue(csvLines(at: url)[1].contains("7.50"))
    }

    func test_export_dataRow_containsFormattedHeartRate() {
        let snapshot = DailySnapshot(date: Date())
        snapshot.restingHeartRate = 58.0
        guard let url = CSVExporter.export(snapshots: [snapshot], entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        XCTAssertTrue(csvLines(at: url)[1].contains("58.00"))
    }

    func test_export_nilFields_renderedAsEmpty() {
        let snapshot = DailySnapshot(date: Date())
        // All health fields left nil
        guard let url = CSVExporter.export(snapshots: [snapshot], entries: [], categories: []) else {
            return XCTFail("Export returned nil URL")
        }
        let row = csvLines(at: url)[1]
        // Consecutive commas indicate empty optional fields
        XCTAssertTrue(row.contains(",,"), "Expected empty fields (consecutive commas) in row: \(row)")
    }

    func test_export_entryValueMappedToCorrectCategory() {
        let cat = TrackingCategory(name: "Café", emoji: "☕", dataType: .counter)
        let snapshot = DailySnapshot(date: Date())
        let entry = DailyEntry(date: snapshot.date, value: 3.0)
        entry.category = cat

        guard let url = CSVExporter.export(
            snapshots: [snapshot], entries: [entry], categories: [cat]
        ) else {
            return XCTFail("Export returned nil URL")
        }
        XCTAssertTrue(csvLines(at: url)[1].hasSuffix("3.00"))
    }

    func test_export_missingEntry_renderedAsEmpty() {
        let cat = TrackingCategory(name: "Café", emoji: "☕", dataType: .counter)
        let snapshot = DailySnapshot(date: Date())
        // No entry for this category on this date

        guard let url = CSVExporter.export(
            snapshots: [snapshot], entries: [], categories: [cat]
        ) else {
            return XCTFail("Export returned nil URL")
        }
        // Last field should be empty (no entry)
        let row = csvLines(at: url)[1]
        XCTAssertTrue(row.hasSuffix(","), "Expected empty last field: \(row)")
    }

    func test_export_returnsValidFileURL() {
        let url = CSVExporter.export(snapshots: [], entries: [], categories: [])
        XCTAssertNotNil(url)
        XCTAssertEqual(url?.pathExtension, "csv")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url!.path))
    }

    // MARK: - Helper

    private func csvLines(at url: URL) -> [String] {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return [] }
        return content.split(separator: "\n", omittingEmptySubsequences: false)
            .map(String.init)
            .filter { !$0.isEmpty }
    }
}
