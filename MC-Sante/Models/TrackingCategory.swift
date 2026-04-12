import SwiftData
import Foundation

// MARK: - MetricDataType

enum MetricDataType: String, Codable, CaseIterable {
    case counter    // 0, 1, 2, 3… (ex: cafés)
    case boolean    // oui/non (ex: sucre raffiné)
    case scale      // 1-5 (ex: stress subjectif)

    var label: String {
        switch self {
        case .counter: return "Compteur"
        case .boolean: return "Oui / Non"
        case .scale:   return "Échelle 1–5"
        }
    }
}

// MARK: - TrackingCategory

@Model
final class TrackingCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var dataType: MetricDataType
    var isBuiltIn: Bool
    var isActive: Bool
    var createdAt: Date
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \DailyEntry.category)
    var entries: [DailyEntry] = []

    init(
        name: String,
        emoji: String,
        dataType: MetricDataType,
        isBuiltIn: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.dataType = dataType
        self.isBuiltIn = isBuiltIn
        self.isActive = true
        self.createdAt = .now
        self.sortOrder = sortOrder
    }
}

// MARK: - Default categories

extension TrackingCategory {
    static let defaultCategories: [(String, String, MetricDataType)] = [
        ("Café",             "☕", .counter),
        ("Sucre raffiné",    "🍬", .boolean),
        ("Stress subjectif", "😰", .scale),
        ("Niveau d'énergie", "⚡", .scale),
        ("Qualité sommeil",  "😴", .scale),
    ]
}
