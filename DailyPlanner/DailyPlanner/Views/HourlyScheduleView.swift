import SwiftUI
import PencilKit

struct HourlyScheduleView: View {
    @EnvironmentObject var store: PlannerStore

    var body: some View {
        ZStack {
            // Background schedule grid
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    ForEach(store.currentPlan.hourlySlots.indices, id: \.self) { index in
                        HourlySlotRow(slot: $store.currentPlan.hourlySlots[index])
                    }
                }
                .padding(.top, 4)
            }

            // Overlay: PencilKit canvas for drawing
            if store.isDrawingMode {
                DrawingCanvasView(
                    drawingData: store.currentPlan.drawingData,
                    onDrawingChanged: { data in
                        store.updateDrawing(data)
                    }
                )
                .allowsHitTesting(true)
            }
        }
    }
}

struct HourlySlotRow: View {
    @Binding var slot: HourlySlot

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Time label
            Text(slot.displayTime)
                .font(.system(size: UIDevice.current.isIPad ? 23.52 : 12, weight: .regular))
                .foregroundColor(.gray)
                .frame(width: UIDevice.current.isIPad ? 98 : 50, alignment: .trailing)
                .padding(.trailing, 6)

            // Separator and content area
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 0.5)

                TextField("", text: $slot.text)
                    .font(.system(size: UIDevice.current.isIPad ? 23.52 : 12))
                    .foregroundColor(.white)
                    .textFieldStyle(.plain)
                    .frame(height: UIDevice.current.isIPad ? 42 : 26)
                    .padding(.horizontal, UIDevice.current.isIPad ? 8 : 4)
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
        }
        .frame(height: UIDevice.current.isIPad ? 48 : 30)
    }
}

#Preview {
    HourlyScheduleView()
        .environmentObject(PlannerStore())
        .preferredColorScheme(.dark)
        .background(Color.black)
}
