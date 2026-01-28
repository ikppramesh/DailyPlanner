import SwiftUI

struct MonthTabsView: View {
    @EnvironmentObject var store: PlannerStore

    private let months: [(name: String, color: Color)] = [
        ("JAN", .red),
        ("FEB", .pink),
        ("MAR", .purple),
        ("APR", Color(red: 0.6, green: 0.4, blue: 0.8)),
        ("MAY", .blue),
        ("JUN", .cyan),
        ("JUL", .teal),
        ("AUG", .green),
        ("SEP", .yellow),
        ("OCT", .orange),
        ("NOV", Color(red: 0.8, green: 0.4, blue: 0.2)),
        ("DEC", Color(red: 0.6, green: 0.2, blue: 0.2))
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Year label at top
            Text(String(store.selectedYear))
                .font(.system(size: UIDevice.current.isIPad ? 17.64 : 9, weight: .bold))
                .foregroundColor(.white)
                .rotationEffect(.degrees(0))
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.4))

            // Month tabs
            ForEach(0..<12, id: \.self) { index in
                MonthTab(
                    name: months[index].name,
                    color: months[index].color,
                    isSelected: store.selectedMonth == index + 1,
                    action: { store.selectMonth(index + 1) }
                )
            }

            Spacer()

            // Week button
            Button(action: {
                // Navigate to week view (future feature)
            }) {
                Text("Week")
                    .font(.system(size: UIDevice.current.isIPad ? 17.64 : 9, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(Color.gray.opacity(0.3))
            }

            // Today button
            Button(action: {
                store.selectDate(Date())
            }) {
                Text("Today")
                    .font(.system(size: UIDevice.current.isIPad ? 17.64 : 9, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .background(Color.blue.opacity(0.6))
            }
        }
        .background(Color.black)
    }
}

struct MonthTab: View {
    let name: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: UIDevice.current.isIPad ? 19.6 : 10, weight: isSelected ? .bold : .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(
                    isSelected ? color : color.opacity(0.7)
                )
                .overlay(
                    isSelected ?
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.white, lineWidth: 1) :
                    nil
                )
        }
    }
}

#Preview {
    MonthTabsView()
        .environmentObject(PlannerStore())
        .preferredColorScheme(.dark)
        .frame(width: 50, height: 600)
        .background(Color.black)
}
