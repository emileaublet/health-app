import XCTest
@testable import MC_Sante

final class DoubleFormattingTests: XCTestCase {

    // MARK: - hoursMinutesString

    func test_hoursMinutesString_7_5_produces7h30() {
        XCTAssertEqual(7.5.hoursMinutesString, "7h30")
    }

    func test_hoursMinutesString_8_0_produces8h00() {
        XCTAssertEqual(8.0.hoursMinutesString, "8h00")
    }

    func test_hoursMinutesString_6_75_produces6h45() {
        XCTAssertEqual(6.75.hoursMinutesString, "6h45")
    }

    func test_hoursMinutesString_0_produces0h00() {
        XCTAssertEqual(0.0.hoursMinutesString, "0h00")
    }

    func test_hoursMinutesString_minutesFormatted2Digits() {
        // 7 hours 5 minutes → "7h05"
        XCTAssertEqual((7.0 + 5.0 / 60.0).hoursMinutesString, "7h05")
    }

    // MARK: - oneDecimal / noDecimal / twoDecimals

    func test_oneDecimal_truncatesToOnePlace() {
        XCTAssertEqual(3.14159.oneDecimal, "3.1")
        XCTAssertEqual(9.95.oneDecimal, "10.0")   // rounds up
    }

    func test_noDecimal_roundsToNearestInteger() {
        XCTAssertEqual(4.4.noDecimal, "4")
        XCTAssertEqual(4.5.noDecimal, "5")   // rounds up at 0.5
        XCTAssertEqual(0.0.noDecimal, "0")
    }

    func test_twoDecimals_producesCorrectPrecision() {
        XCTAssertEqual(3.14159.twoDecimals, "3.14")
        XCTAssertEqual(1.0.twoDecimals, "1.00")
    }

    // MARK: - rounded(to:)

    func test_rounded_to2Places() {
        XCTAssertEqual(3.14159.rounded(to: 2), 3.14, accuracy: 1e-10)
    }

    func test_rounded_to0Places() {
        XCTAssertEqual(3.7.rounded(to: 0), 4.0, accuracy: 1e-10)
        XCTAssertEqual(3.2.rounded(to: 0), 3.0, accuracy: 1e-10)
    }

    func test_rounded_to3Places() {
        XCTAssertEqual(1.23456.rounded(to: 3), 1.235, accuracy: 1e-10)
    }

    // MARK: - formatted(for:)

    func test_formattedForBoolean_1_returnsOui() {
        XCTAssertEqual(1.0.formatted(for: .boolean), "Oui")
    }

    func test_formattedForBoolean_0_returnsNon() {
        XCTAssertEqual(0.0.formatted(for: .boolean), "Non")
    }

    func test_formattedForCounter_showsInteger() {
        XCTAssertEqual(3.0.formatted(for: .counter), "3")
        XCTAssertEqual(0.0.formatted(for: .counter), "0")
        XCTAssertEqual(10.0.formatted(for: .counter), "10")
    }

    func test_formattedForScale_showsInteger() {
        XCTAssertEqual(1.0.formatted(for: .scale), "1")
        XCTAssertEqual(5.0.formatted(for: .scale), "5")
    }

    // MARK: - Optional displayString

    func test_optionalSome_returnsOneDecimalString() {
        let v: Double? = 7.5
        XCTAssertEqual(v.displayString, "7.5")
    }

    func test_optionalSome_integer_returnsOneDecimal() {
        let v: Double? = 8.0
        XCTAssertEqual(v.displayString, "8.0")
    }

    func test_optionalNone_returnsDash() {
        let v: Double? = nil
        XCTAssertEqual(v.displayString, "—")
    }
}
