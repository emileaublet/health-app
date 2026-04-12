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
        f.locale = Locale(identifier: "fr_CA")
        return f.string(from: self)
    }

    var dayOfWeekString: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale(identifier: "fr_CA")
        return f.string(from: self).capitalized
    }

    var dayNumberString: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: self)
    }

    var monthYearString: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "fr_CA")
        return f.string(from: self).capitalized
    }

    /// Génère les N derniers jours en ordre chronologique
    static func lastDays(_ n: Int) -> [Date] {
        let today = Date().startOfDay
        return (0..<n).map { today.daysAgo($0) }.reversed()
    }
}
