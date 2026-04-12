import SwiftUI

struct CalendarStrip: View {
    @Binding var selectedDate: Date
    var markedDates: Set<Date> = []      // dates avec données complètes
    var partialDates: Set<Date> = []     // dates avec données partielles

    private let dayCount = 30

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { date in
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isMarked: markedDates.contains(date.startOfDay),
                            isPartial: partialDates.contains(date.startOfDay)
                        )
                        .id(date)
                        .onTapGesture { selectedDate = date }
                    }
                }
                .padding(.horizontal)
            }
            .onAppear {
                proxy.scrollTo(selectedDate.startOfDay, anchor: .trailing)
            }
            .onChange(of: selectedDate) { _, newDate in
                withAnimation {
                    proxy.scrollTo(newDate.startOfDay, anchor: .center)
                }
            }
        }
    }

    private var days: [Date] {
        Date.lastDays(dayCount)
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isMarked: Bool
    let isPartial: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(date.dayOfWeekString)
                .font(.caption2.weight(.medium))
                .foregroundStyle(isSelected ? .white : .secondary)

            Text(date.dayNumberString)
                .font(.callout.weight(isSelected ? .bold : .regular))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.accentColor : .clear)
                .clipShape(Circle())

            // Indicateur de données
            Circle()
                .fill(dotColor)
                .frame(width: 5, height: 5)
                .opacity((isMarked || isPartial) ? 1 : 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var dotColor: Color {
        isMarked ? .accentColor : .secondary
    }
}
