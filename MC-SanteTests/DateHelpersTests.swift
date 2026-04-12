import XCTest
@testable import MC_Sante

final class DateHelpersTests: XCTestCase {

    private let cal = Calendar.current

    // MARK: - startOfDay

    func test_startOfDay_stripsTimeComponent() {
        // Create a date at 14:30
        let noon = cal.date(bySettingHour: 14, minute: 30, second: 15, of: Date())!
        let start = noon.startOfDay
        let comps = cal.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(comps.hour, 0)
        XCTAssertEqual(comps.minute, 0)
        XCTAssertEqual(comps.second, 0)
    }

    func test_startOfDay_sameCalendarDay() {
        let date = Date()
        XCTAssertTrue(cal.isDate(date.startOfDay, inSameDayAs: date))
    }

    // MARK: - isToday / isYesterday

    func test_isToday_currentDate_returnsTrue() {
        XCTAssertTrue(Date().isToday)
    }

    func test_isToday_yesterday_returnsFalse() {
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }

    func test_isYesterday_yesterday_returnsTrue() {
        let yesterday = cal.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
    }

    func test_isYesterday_today_returnsFalse() {
        XCTAssertFalse(Date().isYesterday)
    }

    // MARK: - daysAgo(_:)

    func test_daysAgo_zero_returnsToday() {
        XCTAssertTrue(cal.isDateInToday(Date().daysAgo(0)))
    }

    func test_daysAgo_one_returnsYesterday() {
        XCTAssertTrue(cal.isDateInYesterday(Date().daysAgo(1)))
    }

    func test_daysAgo_7_returns7DaysBack() {
        let result = Date().daysAgo(7)
        let diff = cal.dateComponents([.day], from: result, to: Date())
        XCTAssertEqual(diff.day, 7)
    }

    // MARK: - adding(days:)

    func test_adding_positiveDays_movesForward() {
        let date = Date()
        let future = date.adding(days: 3)
        let diff = cal.dateComponents([.day], from: date, to: future)
        XCTAssertEqual(diff.day, 3)
    }

    func test_adding_negativeDays_movesBackward() {
        let date = Date()
        let past = date.adding(days: -2)
        let diff = cal.dateComponents([.day], from: past, to: date)
        XCTAssertEqual(diff.day, 2)
    }

    func test_adding_zero_returnsSameDay() {
        let date = Date()
        XCTAssertTrue(cal.isDate(date.adding(days: 0), inSameDayAs: date))
    }

    // MARK: - Date.lastDays(_:)

    func test_lastDays_returnsCorrectCount() {
        XCTAssertEqual(Date.lastDays(7).count, 7)
        XCTAssertEqual(Date.lastDays(30).count, 30)
        XCTAssertEqual(Date.lastDays(1).count, 1)
    }

    func test_lastDays_isChronologicalOrder() {
        let days = Date.lastDays(7)
        for i in 0..<days.count - 1 {
            XCTAssertLessThan(days[i], days[i + 1])
        }
    }

    func test_lastDays_lastElementIsToday() {
        let days = Date.lastDays(7)
        XCTAssertTrue(cal.isDateInToday(days.last!))
    }

    func test_lastDays_firstElementIs6DaysAgo() {
        let days = Date.lastDays(7)
        let expected = Date().daysAgo(6).startOfDay
        XCTAssertTrue(cal.isDate(days.first!, inSameDayAs: expected))
    }

    // MARK: - String formatting

    func test_shortDateString_isNonEmpty() {
        XCTAssertFalse(Date().shortDateString.isEmpty)
    }

    func test_dayOfWeekString_isNonEmpty() {
        XCTAssertFalse(Date().dayOfWeekString.isEmpty)
    }

    func test_dayNumberString_isNumeric() {
        let s = Date().dayNumberString
        XCTAssertNotNil(Int(s), "dayNumberString '\(s)' should be numeric")
    }

    func test_monthYearString_isNonEmpty() {
        XCTAssertFalse(Date().monthYearString.isEmpty)
    }
}
