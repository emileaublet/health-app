import SwiftUI

extension Color {
    // MARK: Brand colours (system-native, no asset dependency)
    static let mcPrimary    = Color.accentColor
    static let mcSecondary  = Color(.secondaryLabel)
    static let mcAccent     = Color.accentColor
    static let mcBackground = Color(.systemBackground)
    static let mcCard       = Color(.secondarySystemBackground)

    // MARK: Metric colours
    static let sleepColor    = Color.indigo
    static let heartColor    = Color.pink
    static let hrvColor      = Color.indigo
    static let activityColor = Color.orange
    static let weatherColor  = Color.cyan
    static let moodColor     = Color.purple
    static let manualColor   = Color.teal

    static func metricColor(for metricName: String) -> Color {
        let name = metricName.lowercased()
        if name.contains("sommeil") || name.contains("sleep") || name.contains("rem") || name.contains("profond") || name.contains("deep") {
            return .sleepColor
        } else if name.contains("hrv") {
            return .hrvColor
        } else if name.contains("fc") || name.contains("heart") || name.contains("tension") {
            return .heartColor
        } else if name.contains("calorie") || name.contains("exercice") || name.contains("exercise") || name.contains("activité") || name.contains("activity") {
            return .activityColor
        } else if name.contains("temp") || name.contains("pression") || name.contains("pressure") || name.contains("humidité") || name.contains("humidity") {
            return .weatherColor
        } else if name.contains("humeur") || name.contains("mood") || name.contains("stress") {
            return .moodColor
        } else {
            return .manualColor
        }
    }
}

// MARK: - Gradient helpers

extension LinearGradient {
    static var mcBackground: LinearGradient {
        LinearGradient(
            colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
