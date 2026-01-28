import SwiftUI
import PencilKit

struct ContentView: View {
    @EnvironmentObject var store: PlannerStore
    @StateObject private var googleService = GoogleCalendarService()
    @StateObject private var storageService = DataStorageService()
    @State private var showGoogleCalendarSheet = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HeaderView(googleService: googleService, storageService: storageService)

                Divider().background(Color.gray.opacity(0.5))

                // Main Content with Drawing Overlay
                ZStack {
                    HStack(spacing: 0) {
                        // Left Panel
                        leftPanel

                        // Vertical Divider
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1)

                        // Right Sidebar - Month Tabs
                        MonthTabsView()
                            .frame(width: 50)
                    }
                    
                    // Drawing Canvas Overlay
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
        .onTapGesture {
            // Dismiss keyboard when tapping outside on iPhone only
            if !UIDevice.current.isIPad {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
        .sheet(isPresented: $showGoogleCalendarSheet) {
            GoogleCalendarSettingsView(googleService: googleService)
                .environmentObject(store)
        }
        .onAppear {
            // Use the storage service for the store
            store.storageService = storageService
        }
    }

    private var leftPanel: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    // Mini Calendar
                    MiniCalendarView()
                        .padding(.horizontal, 8)
                        .padding(.top, 8)

                    Divider().background(Color.gray.opacity(0.3))
                        .padding(.horizontal, 8)

                    // Task List with checkboxes
                    TaskListView()
                        .padding(.horizontal, 8)

                    Divider().background(Color.gray.opacity(0.3))
                        .padding(.horizontal, 8)

                    // Priority List
                    PriorityListView()
                        .padding(.horizontal, 8)

                    Divider().background(Color.gray.opacity(0.3))
                        .padding(.horizontal, 8)

                    // Notes area (empty lines)
                    NotesAreaView()
                        .padding(.horizontal, 8)
                }
            }

            Spacer()

            // Habit Tracker
            HabitTrackerView()
                .padding(.horizontal, 8)
                .padding(.bottom, 4)

            Divider().background(Color.gray.opacity(0.3))
                .padding(.horizontal, 8)

            // Mood Tracker
            MoodTrackerView()
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
    }
}

// MARK: - Notes Area
struct NotesAreaView: View {
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 28)
                    .overlay(
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 0.5),
                        alignment: .bottom
                    )
            }
        }
    }
}

// MARK: - Drawing Canvas (PencilKit)
struct DrawingCanvasView: UIViewRepresentable {
    var drawingData: Data?
    var onDrawingChanged: (Data) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput  // Allow both pencil and finger
        canvas.tool = PKInkingTool(.pen, color: .white, width: 2)
        canvas.delegate = context.coordinator

        // Load existing drawing
        if let data = drawingData,
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        // Update drawing if data changed externally
        if let data = drawingData,
           let drawing = try? PKDrawing(data: data),
           canvas.drawing.dataRepresentation() != data {
            canvas.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var onDrawingChanged: (Data) -> Void

        init(onDrawingChanged: @escaping (Data) -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let data = canvasView.drawing.dataRepresentation()
            onDrawingChanged(data)
        }
    }
}

// MARK: - Google Calendar Settings
struct GoogleCalendarSettingsView: View {
    @EnvironmentObject var store: PlannerStore
    @Environment(\.dismiss) var dismiss
    @ObservedObject var googleService: GoogleCalendarService

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("Google Calendar Sync")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Connect your Google Calendar to see events in your daily planner.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                if googleService.isAuthenticated {
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.headline)

                    Button("Sync Now") {
                        googleService.fetchEvents(for: store.selectedDate) { events in
                            store.calendarEvents = events
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Disconnect") {
                        googleService.signOut()
                    }
                    .foregroundColor(.red)
                } else {
                    Button(action: {
                        googleService.signIn()
                    }) {
                        HStack {
                            Image(systemName: "person.crop.circle.badge.plus")
                            Text("Sign in with Google")
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PlannerStore())
}
