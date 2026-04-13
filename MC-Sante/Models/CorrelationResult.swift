import SwiftData
import Foundation

// MARK: - CorrelationStrength

enum CorrelationStrength: String, Codable {
    case weak       // |r| 0.3–0.5
    case moderate   // |r| 0.5–0.7
    case strong     // |r| > 0.7

    var label: String {
        switch self {
        case .weak:     return "Faible"
        case .moderate: return "Modérée"
        case .strong:   return "Forte"
        }
    }

    var localizedLabel: String {
        switch self {
        case .weak:     return L10n.strengthWeak
        case .moderate: return L10n.strengthModerate
        case .strong:   return L10n.strengthStrong
        }
    }

    var colorName: String {
        switch self {
        case .weak:     return "CorrelationWeak"
        case .moderate: return "CorrelationModerate"
        case .strong:   return "CorrelationStrong"
        }
    }
}

// MARK: - CorrelationResult

@Model
final class CorrelationResult {
    @Attribute(.unique) var id: UUID
    var generatedAt: Date
    var metricA: String          // clé lisible, ex: "Café"
    var metricB: String          // clé lisible, ex: "Sommeil (heures)"
    var emojiA: String
    var emojiB: String
    var pearsonR: Double         // coefficient -1 à +1
    var sampleSize: Int          // nombre de jours avec données
    var lagDays: Int             // 0 = même jour, 1 = lendemain
    var windowDays: Int          // 7, 14, ou 30
    var strength: CorrelationStrength
    var insightText: String      // phrase lisible générée
    var isPositive: Bool         // corrélation positive ou négative

    init(
        metricA: String,
        metricB: String,
        emojiA: String = "",
        emojiB: String = "",
        pearsonR: Double,
        sampleSize: Int,
        lagDays: Int,
        windowDays: Int,
        insightText: String
    ) {
        self.id = UUID()
        self.generatedAt = .now
        self.metricA = metricA
        self.metricB = metricB
        self.emojiA = emojiA
        self.emojiB = emojiB
        self.pearsonR = pearsonR
        self.sampleSize = sampleSize
        self.lagDays = lagDays
        self.windowDays = windowDays
        self.strength = abs(pearsonR) > 0.7 ? .strong : abs(pearsonR) > 0.5 ? .moderate : .weak
        self.insightText = insightText
        self.isPositive = pearsonR > 0
    }
}
