import SwiftUI
import UserNotifications

@main
struct DailyPlannerApp: App {
    @StateObject private var plannerStore = PlannerStore()
    @StateObject private var notificationService = NotificationService.shared
    
    init() {
        // Request notification permissions on app launch
        NotificationService.shared.requestAuthorization()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(plannerStore)
                .environmentObject(notificationService)
                .preferredColorScheme(.dark)
                .onAppear {
                    // Always load today's date when app opens
                    let today = Calendar.current.startOfDay(for: Date())
                    if !Calendar.current.isDate(plannerStore.selectedDate, inSameDayAs: today) {
                        plannerStore.selectDate(today)
                    }
                    // Update notifications with current pending tasks
                    notificationService.updateNotificationWithPendingTasks(tasks: plannerStore.currentPlan.tasks)
                }
        }
    }
}
