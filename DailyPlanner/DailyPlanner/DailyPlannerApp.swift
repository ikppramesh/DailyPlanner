import SwiftUI
import UserNotifications

@main
struct DailyPlannerApp: App {
    @StateObject private var plannerStore = PlannerStore()
    @StateObject private var notificationService = NotificationService.shared
    @Environment(\.scenePhase) private var scenePhase
    
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
                    performDailyRollover()
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    // Check for rollover when app becomes active
                    if newPhase == .active {
                        performDailyRollover()
                    }
                }
        }
    }
    
    private func performDailyRollover() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Check if we need to rollover tasks from previous dates
        let lastRolloverDate = UserDefaults.standard.object(forKey: "lastRolloverDate") as? Date
        let shouldRollover = lastRolloverDate == nil || !Calendar.current.isDate(lastRolloverDate!, inSameDayAs: today)
        
        if shouldRollover {
            // Perform rollover of incomplete tasks
            plannerStore.rolloverIncompleteTasks()
            
            // Save today's date as last rollover date
            UserDefaults.standard.set(today, forKey: "lastRolloverDate")
        }
        
        // Always navigate to today's date when app opens
        if !Calendar.current.isDate(plannerStore.selectedDate, inSameDayAs: today) {
            plannerStore.selectDate(today)
        }
        
        // Update notifications with current pending tasks
        notificationService.updateNotificationWithPendingTasks(tasks: plannerStore.currentPlan.tasks)
    }
}
