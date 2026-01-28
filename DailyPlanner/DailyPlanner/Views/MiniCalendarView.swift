import SwiftUI

struct MiniCalendarView: View {
    @EnvironmentObject var store: PlannerStore

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: UIDevice.current.isIPad ? 8 : 4) {
            // Month Title
            Text(store.monthName)
                .font(.system(size: UIDevice.current.isIPad ? 27.44 : 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.bottom, UIDevice.current.isIPad ? 4 : 2)

            // Day headers
            HStack(spacing: 0) {
                ForEach(daysOfWeek.indices, id: \.self) { index in
                    Text(daysOfWeek[index])
                        .font(.system(size: UIDevice.current.isIPad ? 19.6 : 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let days = generateDaysInMonth()
            let rows = days.chunked(into: 7)

            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex].indices, id: \.self) { colIndex in
                        let day = rows[rowIndex][colIndex]
                        if day > 0 {
                            Button(action: {
                                selectDay(day)
                            }) {
                                Text("\(day)")
                                    .font(.system(size: UIDevice.current.isIPad ? 21.56 : 11, weight: day == store.selectedDay ? .bold : .regular, design: .monospaced))
                                    .foregroundColor(day == store.selectedDay ? .black : .white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: UIDevice.current.isIPad ? 39.2 : 20)
                                    .background(
                                        day == store.selectedDay ?
                                        Circle().fill(Color.cyan).frame(width: UIDevice.current.isIPad ? 43.12 : 22, height: UIDevice.current.isIPad ? 43.12 : 22) :
                                        nil
                                    )
                            }
                        } else {
                            Text("")
                                .frame(maxWidth: .infinity)
                                .frame(height: 20)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func selectDay(_ day: Int) {
        var components = calendar.dateComponents([.year, .month], from: store.selectedDate)
        components.day = day
        if let newDate = calendar.date(from: components) {
            store.selectDate(newDate)
        }
    }

    private func generateDaysInMonth() -> [Int] {
        let components = calendar.dateComponents([.year, .month], from: store.selectedDate)
        guard let firstDayOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstDayOfMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        let offset = firstWeekday - 1 // Sunday = 1

        var days: [Int] = Array(repeating: 0, count: offset)
        days.append(contentsOf: Array(range))

        // Pad to complete the last row
        while days.count % 7 != 0 {
            days.append(0)
        }

        return days
    }
}

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    MiniCalendarView()
        .environmentObject(PlannerStore())
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
}
