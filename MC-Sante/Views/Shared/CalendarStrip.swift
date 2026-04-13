import SwiftUI

struct CalendarStrip: View {
    @Binding var selectedDate: Date
    var markedDates: Set<Date> = []      // dates with complete data (accent dot)
    var partialDates: Set<Date> = []     // dates with partial data (secondary dot)

    private let totalDays = 60 // how far back we show

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(days, id: \.self) { date in
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: date.isToday,
                            isMarked: markedDates.contains(date.startOfDay),
                            isPartial: partialDates.contains(date.startOfDay)
                        )
                        .id(date)
                        .onTapGesture { selectedDate = date.startOfDay }
                    }
                }
                .padding(.horizontal, 8)
            }
            .onAppear {
                proxy.scrollTo(selectedDate.startOfDay, anchor: .center)
            }
            .onChange(of: selectedDate) { _, newDate in
                withAnimation(.easeInOut(duration: 0.25)) {
                    proxy.scrollTo(newDate.startOfDay, anchor: .center)
                }
            }
        }
    }

    /// All days from `totalDays` ago up to today (no future days).
    private var days: [Date] {
        let today = Date().startOfDay
        return (0..<totalDays).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: -offset, to: today)
        }.reversed()
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let isMarked: Bool
    let isPartial: Bool

    var body: some View {
        VStack(spacing: 4) {
            // Day-of-week letter (D, L, M, …)
            Text(dayOfWeekLetter)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isSelected ? .primary : .secondary)

            // Day number in circle
            ZStack {
                if isSelected {
                    Circle()
                        .fill(Color(.label))
                        .frame(width: 36, height: 36)
                }

                Text(date.dayNumberString)
                    .font(.callout.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(foregroundColor)
            }
            .frame(width: 36, height: 36)

            // Data indicator dot
            Circle()
                .fill(dotColor)
                .frame(width: 5, height: 5)
                .opacity((isMarked || isPartial) ? 1 : 0)
        }
        .frame(width: 44)
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var foregroundColor: Color {
        if isSelected {
            return Color(.systemBackground)
        }
        if isToday {
            return .red
        }
        // Grey out weekends slightly
        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 {
            return .secondary
        }
        return .primary
    }

    private var dayOfWeekLetter: String {
        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.locale
        formatter.dateFormat = "EEEEE" // Single letter (D, L, M, M, J, V, S)
        return formatter.string(from: date).uppercased()
    }

    private var dotColor: Color {
        isMarked ? .accentColor : .secondary
    }
}
