import Foundation
import SwiftData

// MARK: - Codable transfer structs (mirrors of SwiftData @Model classes)

struct BackupPayload: Codable {
    let version: Int
    let exportedAt: Date
    let snapshots: [SnapshotDTO]
    let entries: [EntryDTO]
    let categories: [CategoryDTO]
}

struct SnapshotDTO: Codable {
    let date: Date
    let sleepDurationHours: Double?
    let sleepREMMinutes: Double?
    let sleepDeepMinutes: Double?
    let sleepCoreMinutes: Double?
    let restingHeartRate: Double?
    let hrvSDNN: Double?
    let averageHeartRate: Double?
    let activeCalories: Double?
    let exerciseMinutes: Double?
    let menstrualFlowRaw: Int?
    let systolic: Double?
    let diastolic: Double?
    let moodValence: Double?
    let moodLabels: String?
    let temperatureCelsius: Double?
    let pressureHPa: Double?
    let humidityPercent: Double?

    init(from snapshot: DailySnapshot) {
        self.date = snapshot.date
        self.sleepDurationHours = snapshot.sleepDurationHours
        self.sleepREMMinutes = snapshot.sleepREMMinutes
        self.sleepDeepMinutes = snapshot.sleepDeepMinutes
        self.sleepCoreMinutes = snapshot.sleepCoreMinutes
        self.restingHeartRate = snapshot.restingHeartRate
        self.hrvSDNN = snapshot.hrvSDNN
        self.averageHeartRate = snapshot.averageHeartRate
        self.activeCalories = snapshot.activeCalories
        self.exerciseMinutes = snapshot.exerciseMinutes
        self.menstrualFlowRaw = snapshot.menstrualFlowRaw
        self.systolic = snapshot.systolic
        self.diastolic = snapshot.diastolic
        self.moodValence = snapshot.moodValence
        self.moodLabels = snapshot.moodLabels
        self.temperatureCelsius = snapshot.temperatureCelsius
        self.pressureHPa = snapshot.pressureHPa
        self.humidityPercent = snapshot.humidityPercent
    }

    func toModel() -> DailySnapshot {
        let snap = DailySnapshot(date: date)
        snap.sleepDurationHours = sleepDurationHours
        snap.sleepREMMinutes = sleepREMMinutes
        snap.sleepDeepMinutes = sleepDeepMinutes
        snap.sleepCoreMinutes = sleepCoreMinutes
        snap.restingHeartRate = restingHeartRate
        snap.hrvSDNN = hrvSDNN
        snap.averageHeartRate = averageHeartRate
        snap.activeCalories = activeCalories
        snap.exerciseMinutes = exerciseMinutes
        snap.menstrualFlowRaw = menstrualFlowRaw
        snap.systolic = systolic
        snap.diastolic = diastolic
        snap.moodValence = moodValence
        snap.moodLabels = moodLabels
        snap.temperatureCelsius = temperatureCelsius
        snap.pressureHPa = pressureHPa
        snap.humidityPercent = humidityPercent
        snap.isComplete = true
        return snap
    }
}

struct CategoryDTO: Codable {
    let name: String
    let emoji: String
    let dataType: String // "counter", "boolean", "scale"
    let isBuiltIn: Bool
    let isActive: Bool
    let sortOrder: Int

    init(from category: TrackingCategory) {
        self.name = category.name
        self.emoji = category.emoji
        self.dataType = category.dataType.rawValue
        self.isBuiltIn = category.isBuiltIn
        self.isActive = category.isActive
        self.sortOrder = category.sortOrder
    }

    func toModel() -> TrackingCategory {
        let cat = TrackingCategory(
            name: name,
            emoji: emoji,
            dataType: MetricDataType(rawValue: dataType) ?? .counter,
            isBuiltIn: isBuiltIn,
            sortOrder: sortOrder
        )
        cat.isActive = isActive
        return cat
    }
}

struct EntryDTO: Codable {
    let date: Date
    let value: Double
    let note: String?
    let categoryName: String? // link by name since IDs won't match across devices

    init(from entry: DailyEntry) {
        self.date = entry.date
        self.value = entry.value
        self.note = entry.note
        self.categoryName = entry.category?.name
    }
}

// MARK: - CloudBackupService

enum CloudBackupService {
    private static let backupFileName = "mc-sante-backup.json"

    // MARK: iCloud URL

    /// Returns the iCloud Documents directory, or nil if iCloud is unavailable.
    static var iCloudDocumentsURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
    }

    /// Whether iCloud is available on this device.
    static var isICloudAvailable: Bool {
        iCloudDocumentsURL != nil
    }

    private static var backupURL: URL? {
        iCloudDocumentsURL?.appendingPathComponent(backupFileName)
    }

    /// Falls back to local documents if iCloud is unavailable.
    private static var localBackupURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(backupFileName)
    }

    // MARK: Backup

    static func backup(context: ModelContext) throws -> URL {
        let snapshotDescriptor = FetchDescriptor<DailySnapshot>(
            sortBy: [SortDescriptor(\.date)]
        )
        let snapshots = (try? context.fetch(snapshotDescriptor)) ?? []

        let categoryDescriptor = FetchDescriptor<TrackingCategory>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let categories = (try? context.fetch(categoryDescriptor)) ?? []

        let entryDescriptor = FetchDescriptor<DailyEntry>()
        let entries = (try? context.fetch(entryDescriptor)) ?? []

        let payload = BackupPayload(
            version: 1,
            exportedAt: .now,
            snapshots: snapshots.map { SnapshotDTO(from: $0) },
            entries: entries.map { EntryDTO(from: $0) },
            categories: categories.map { CategoryDTO(from: $0) }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)

        // Write to iCloud if available, otherwise local
        let targetURL: URL
        if let icloudURL = backupURL {
            // Ensure Documents directory exists in iCloud container
            let docsDir = icloudURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: docsDir.path) {
                try FileManager.default.createDirectory(at: docsDir, withIntermediateDirectories: true)
            }
            targetURL = icloudURL
        } else {
            targetURL = localBackupURL
        }

        try data.write(to: targetURL, options: .atomic)
        return targetURL
    }

    // MARK: Restore

    static func restore(context: ModelContext) throws -> Int {
        // Try iCloud first, then local
        let sourceURL: URL
        if let icloudURL = backupURL, FileManager.default.fileExists(atPath: icloudURL.path) {
            sourceURL = icloudURL
        } else if FileManager.default.fileExists(atPath: localBackupURL.path) {
            sourceURL = localBackupURL
        } else {
            throw BackupError.noBackupFound
        }

        let data = try Data(contentsOf: sourceURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(BackupPayload.self, from: data)

        // Clear existing data
        try context.delete(model: DailySnapshot.self)
        try context.delete(model: DailyEntry.self)
        try context.delete(model: CorrelationResult.self)
        try context.delete(model: TrackingCategory.self)

        // Restore categories
        var categoryMap: [String: TrackingCategory] = [:]
        for dto in payload.categories {
            let cat = dto.toModel()
            context.insert(cat)
            categoryMap[cat.name] = cat
        }

        // Restore snapshots
        for dto in payload.snapshots {
            context.insert(dto.toModel())
        }

        // Restore entries with category linking
        for dto in payload.entries {
            let entry = DailyEntry(date: dto.date, value: dto.value, note: dto.note)
            if let catName = dto.categoryName {
                entry.category = categoryMap[catName]
            }
            context.insert(entry)
        }

        try context.save()

        return payload.snapshots.count + payload.entries.count + payload.categories.count
    }

    // MARK: Backup info

    static func lastBackupDate() -> Date? {
        let urls = [backupURL, localBackupURL].compactMap { $0 }
        for url in urls {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
               let date = attrs[.modificationDate] as? Date {
                return date
            }
        }
        return nil
    }
}

// MARK: - BackupError

enum BackupError: LocalizedError {
    case noBackupFound

    var errorDescription: String? {
        switch self {
        case .noBackupFound:
            return LocalizationManager.shared.language == .french
                ? "Aucune sauvegarde trouvée."
                : "No backup found."
        }
    }
}
