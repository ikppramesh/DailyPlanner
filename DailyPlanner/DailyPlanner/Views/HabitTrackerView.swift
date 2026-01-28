import SwiftUI

struct HabitTrackerView: View {
    @EnvironmentObject var store: PlannerStore

    var body: some View {
        HStack(spacing: UIDevice.current.isIPad ? 10 : 6) {
            ForEach(HabitType.allCases, id: \.rawValue) { habit in
                HabitButton(
                    habit: habit,
                    isCompleted: store.currentPlan.completedHabits.contains(habit.rawValue),
                    action: { store.toggleHabit(habit) }
                )
            }
        }
        .padding(.vertical, UIDevice.current.isIPad ? 8 : 4)
    }
}

struct HabitButton: View {
    let habit: HabitType
    let isCompleted: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: habit.icon)
                    .font(.system(size: UIDevice.current.isIPad ? 21.56 : 11))
                    .foregroundColor(isCompleted ? .green : .gray)
                    .frame(width: UIDevice.current.isIPad ? 41.16 : 21, height: UIDevice.current.isIPad ? 41.16 : 21)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isCompleted ? Color.green : Color.gray.opacity(0.4), lineWidth: 1.5)
                    )
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HabitTrackerView()
        .environmentObject(PlannerStore())
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
}
