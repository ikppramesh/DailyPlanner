import SwiftUI

struct PriorityListView: View {
    @EnvironmentObject var store: PlannerStore

    var body: some View {
        VStack(spacing: 0) {
            ForEach(store.currentPlan.priorities.indices, id: \.self) { index in
                PriorityRow(priority: $store.currentPlan.priorities[index])
            }
        }
    }
}

struct PriorityRow: View {
    @Binding var priority: PriorityItem

    var body: some View {
        HStack(spacing: 8) {
            // Number
            Text("\(priority.number)")
                .font(.system(size: UIDevice.current.isIPad ? 27.44 : 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: UIDevice.current.isIPad ? 39 : 20, alignment: .leading)

            // Text field
            TextField("", text: $priority.text)
                .font(.system(size: UIDevice.current.isIPad ? 25.48 : 13))
                .foregroundColor(.white)
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
        }
        .frame(height: UIDevice.current.isIPad ? 36 : 20)
        .overlay(
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

#Preview {
    PriorityListView()
        .environmentObject(PlannerStore())
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
}
