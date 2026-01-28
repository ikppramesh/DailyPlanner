import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var store: PlannerStore

    var body: some View {
        VStack(spacing: 0) {
            ForEach(store.currentPlan.tasks.indices, id: \.self) { index in
                TaskRow(
                    task: $store.currentPlan.tasks[index],
                    onToggle: { store.toggleTask(index) },
                    onDelete: { store.deleteTask(index) }
                )
            }
            
            // Add More Button
            Button(action: {
                store.addTask()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: UIDevice.current.isIPad ? 25.48 : 13))
                    Text("Add More")
                        .font(.system(size: UIDevice.current.isIPad ? 21.56 : 11, weight: .medium))
                }
                .foregroundColor(.cyan)
                .frame(maxWidth: .infinity)
                .frame(height: UIDevice.current.isIPad ? 40 : 24)
            }
            .buttonStyle(.plain)
            .padding(.top, UIDevice.current.isIPad ? 8 : 4)
        }
    }
}

struct TaskRow: View {
    @Binding var task: TaskItem
    var onToggle: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.square.fill" : "square")
                    .font(.system(size: UIDevice.current.isIPad ? 31.36 : 16))
                    .foregroundColor(task.isCompleted ? .green : .gray)
            }
            .buttonStyle(.plain)

            // Text field
            TextField("", text: $task.text)
                .font(.system(size: UIDevice.current.isIPad ? 25.48 : 13))
                .foregroundColor(task.isCompleted ? .gray : .white)
                .strikethrough(task.isCompleted)
                .textFieldStyle(.plain)
                .toolbar {
                    if !UIDevice.current.isIPad {
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button("Done") {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            }
                        }
                    }
                }
            
            // Delete button (shown when there's text or when task is completed)
            if !task.text.isEmpty || task.isCompleted {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: UIDevice.current.isIPad ? 25.48 : 13))
                        .foregroundColor(.red.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: UIDevice.current.isIPad ? 44 : 24)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

#Preview {
    TaskListView()
        .environmentObject(PlannerStore())
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
}
