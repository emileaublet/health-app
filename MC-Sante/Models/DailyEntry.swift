import SwiftData
import Foundation

@Model
final class DailyEntry {
    @Attribute(.unique) var id: UUID
    var date: Date          // normalisé à minuit (startOfDay)
    var value: Double       // 0/1 pour bool, compteur, ou 1-5 pour scale
    var note: String?
    var category: TrackingCategory?

    init(date: Date, value: Double, note: String? = nil) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.value = value
        self.note = note
    }
}
