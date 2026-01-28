import Foundation
import UserNotifications
import SwiftUI

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    private init() {}
    
    // Request notification permissions
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
                self.scheduleHourlyNotifications()
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // Schedule hourly notifications from 10 AM to 11 PM, Monday to Friday
    func scheduleHourlyNotifications() {
        let center = UNUserNotificationCenter.current()
        
        // Remove all existing notifications first
        center.removeAllPendingNotificationRequests()
        
        // Schedule notifications for each hour from 10 AM to 11 PM
        for hour in 10...23 {
            for weekday in 2...6 { // Monday = 2, Friday = 6
                let content = UNMutableNotificationContent()
                content.title = "Task Reminder"
                content.body = "Check your pending tasks for today"
                content.sound = .default
                content.categoryIdentifier = "TASK_REMINDER"
                
                // Create date components for the notification
                var dateComponents = DateComponents()
                dateComponents.hour = hour
                dateComponents.minute = 0
                dateComponents.weekday = weekday
                
                // Create trigger that repeats weekly
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                // Create request with unique identifier
                let identifier = "hourly_reminder_\(weekday)_\(hour)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                // Schedule the notification
                center.add(request) { error in
                    if let error = error {
                        print("Error scheduling notification: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        print("Scheduled hourly notifications from 10 AM to 11 PM, Monday to Friday")
    }
    
    // Update notification content with pending tasks
    func updateNotificationWithPendingTasks(tasks: [TaskItem]) {
        let pendingTasks = tasks.filter { !$0.isCompleted && !$0.text.isEmpty }
        
        if pendingTasks.isEmpty {
            return
        }
        
        // Get the next scheduled notification and update it
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // Find the next notification that will fire
            let now = Date()
            let calendar = Calendar.current
            
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextTriggerDate = trigger.nextTriggerDate(),
                   nextTriggerDate > now {
                    
                    // Update content with pending tasks
                    let content = UNMutableNotificationContent()
                    content.title = "Task Reminder"
                    
                    let taskCount = pendingTasks.count
                    if taskCount == 1 {
                        content.body = "You have 1 pending task: \(pendingTasks[0].text)"
                    } else if taskCount <= 3 {
                        let taskList = pendingTasks.map { $0.text }.joined(separator: ", ")
                        content.body = "You have \(taskCount) pending tasks: \(taskList)"
                    } else {
                        content.body = "You have \(taskCount) pending tasks to complete"
                    }
                    
                    content.sound = .default
                    content.categoryIdentifier = "TASK_REMINDER"
                    content.badge = NSNumber(value: taskCount)
                    
                    // Create new request with the same trigger
                    let updatedRequest = UNNotificationRequest(
                        identifier: request.identifier,
                        content: content,
                        trigger: trigger
                    )
                    
                    // Update the notification
                    UNUserNotificationCenter.current().add(updatedRequest)
                }
            }
        }
    }
    
    // Check notification status
    func checkNotificationStatus(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // Manually trigger a test notification (for testing purposes)
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Task Reminder Test"
        content.body = "Hourly notifications are now active!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Test notification error: \(error.localizedDescription)")
            } else {
                print("Test notification scheduled")
            }
        }
    }
}
