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
    static let activityColor = Color.orange
    static let weatherColor  = Color.cyan
    static let moodColor     = Color.purple
    static let manualColor   = Color.teal

    // MARK: Correlation strength colours
    static let correlationWeak     = Color.yellow
    static let correlationModerate = Color.orange
    static let correlationStrong   = Color.red

    // MARK: Helpers
    static func correlationColor(for r: Double) -> Color {
        switch abs(r) {
        case 0.7...: return .correlationStrong
        case 0.5...: return .correlationModerate
        default:     return .correlationWeak
        }
    }

    static func metricColor(for metricName: String) -> Color {
        if metricName.contains("Sommeil") || metricName.contains("REM") || metricName.contains("profond") {
            return .sleepColor
        } else if metricName.contains("FC") || metricName.contains("HRV") || metricName.contains("Tension") {
            return .heartColor
        } else if metricName.contains("Calories") || metricName.contains("exercice") || metricName.contains("Activité") {
            return .activityColor
        } else if metricName.contains("Temp") || metricName.contains("Pression") || metricName.contains("Humidité") {
            return .weatherColor
        } else if metricName.contains("Humeur") || metricName.contains("stress") || metricName.contains("Stress") {
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
