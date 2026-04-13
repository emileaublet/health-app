import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: self)!
    }

    func adding(days n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: n, to: self)!
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    var shortDateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale = LocalizationManager.shared.locale
        return f.string(from: self)
    }

    var dayOfWeekString: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = LocalizationManager.shared.locale
        return f.string(from: self).capitalized
    }

    /// Single-letter weekday initial (e.g. "D", "L", "M" in French).
    var weekdayInitial: String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        f.locale = LocalizationManager.shared.locale
        return f.string(from: self).uppercased()
    }

    var dayNumberString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: self)
    }

    /// "Aujourd'hui" / "Today" if today, otherwise "13 avril" (FR) or "April 13" (EN).
    var dayMonthString: String {
        if Calendar.current.isDateInToday(self) {
            return LocalizationManager.shared.language == .french ? "Aujourd'hui" : "Today"
        }
        let f = DateFormatter()
        let locale = LocalizationManager.shared.locale
        f.locale = locale
        f.dateFormat = DateFormatter.dateFormat(fromTemplate: "d MMMM", options: 0, locale: locale)
        return f.string(from: self)
    }

    var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = LocalizationManager.shared.locale
        return f.string(from: self).capitalized
    }

    /// Génère les N derniers jours en ordre chronologique
    static func lastDays(_ n: Int) -> [Date] {
        let today = Date().startOfDay
        return (0..<n).map { today.daysAgo($0) }.reversed()
    }
}
