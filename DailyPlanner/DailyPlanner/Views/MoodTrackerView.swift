import SwiftUI

struct MoodTrackerView: View {
    @EnvironmentObject var store: PlannerStore

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Mood.allCases, id: \.rawValue) { mood in
                MoodButton(
                    mood: mood,
                    isSelected: store.currentPlan.selectedMood == mood.rawValue,
                    action: { store.selectMood(mood) }
                )
            }
        }
    }
}

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .stroke(isSelected ? Color.yellow : Color.gray.opacity(0.4), lineWidth: isSelected ? 2 : 1)
                    .frame(width: 22, height: 22)
                    .background(
                        isSelected ? Circle().fill(Color.yellow.opacity(0.15)) : nil
                    )

                // Face drawing
                FaceView(mood: mood)
                    .frame(width: 18, height: 18)
            }
        }
        .buttonStyle(.plain)
    }
}

struct FaceView: View {
    let mood: Mood

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let eyeY = center.y - size.height * 0.1
            let leftEyeX = center.x - size.width * 0.18
            let rightEyeX = center.x + size.width * 0.18

            // Eyes
            let eyeSize: CGFloat = 2.5
            context.fill(
                Path(ellipseIn: CGRect(x: leftEyeX - eyeSize, y: eyeY - eyeSize, width: eyeSize * 2, height: eyeSize * 2)),
                with: .color(.gray)
            )
            context.fill(
                Path(ellipseIn: CGRect(x: rightEyeX - eyeSize, y: eyeY - eyeSize, width: eyeSize * 2, height: eyeSize * 2)),
                with: .color(.gray)
            )

            // Mouth
            let mouthY = center.y + size.height * 0.15
            var mouthPath = Path()

            switch mood {
            case .great:
                mouthPath.move(to: CGPoint(x: center.x - 6, y: mouthY - 1))
                mouthPath.addQuadCurve(
                    to: CGPoint(x: center.x + 6, y: mouthY - 1),
                    control: CGPoint(x: center.x, y: mouthY + 5)
                )
            case .good:
                mouthPath.move(to: CGPoint(x: center.x - 5, y: mouthY))
                mouthPath.addQuadCurve(
                    to: CGPoint(x: center.x + 5, y: mouthY),
                    control: CGPoint(x: center.x, y: mouthY + 3)
                )
            case .okay:
                mouthPath.move(to: CGPoint(x: center.x - 4, y: mouthY))
                mouthPath.addLine(to: CGPoint(x: center.x + 4, y: mouthY))
            case .bad:
                mouthPath.move(to: CGPoint(x: center.x - 5, y: mouthY + 2))
                mouthPath.addQuadCurve(
                    to: CGPoint(x: center.x + 5, y: mouthY + 2),
                    control: CGPoint(x: center.x, y: mouthY - 2)
                )
            case .terrible:
                mouthPath.move(to: CGPoint(x: center.x - 5, y: mouthY + 3))
                mouthPath.addQuadCurve(
                    to: CGPoint(x: center.x + 5, y: mouthY + 3),
                    control: CGPoint(x: center.x, y: mouthY - 3)
                )
            }

            context.stroke(mouthPath, with: .color(.gray), lineWidth: 1.5)
        }
    }
}

#Preview {
    MoodTrackerView()
        .environmentObject(PlannerStore())
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.black)
}
