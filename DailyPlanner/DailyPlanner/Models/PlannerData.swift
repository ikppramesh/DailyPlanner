import SwiftUI
import PencilKit
import Combine

// MARK: - Task Item
struct TaskItem: Identifiable, Codable {
    let id: UUID
    var text: String
    var isCompleted: Bool

    init(id: UUID = UUID(), text: String = "", isCompleted: Bool = false) {
        self.id = id
        self.text = text
        self.isCompleted = isCompleted
    }
}

// MARK: - Priority Item
struct PriorityItem: Identifiable, Codable {
    let id: UUID
    var number: Int
    var text: String

    init(id: UUID = UUID(), number: Int, text: String = "") {
        self.id = id
        self.number = number
        self.text = text
    }
}

// MARK: - Hourly Slot
struct HourlySlot: Identifiable, Codable {
    let id: UUID
    var hour: Int // 7-18 (7am to 6pm)
    var text: String

    init(id: UUID = UUID(), hour: Int, text: String = "") {
        self.id = id
        self.hour = hour
        self.text = text
    }

    var displayTime: String {
        if hour == 0 { return "12 am" }
        if hour < 12 { return "\(hour) am" }
        if hour == 12 { return "12 pm" }
        return "\(hour - 12) pm"
    }
}

// MARK: - Habit Type
enum HabitType: String, Codable, CaseIterable {
    case water
    case exercise
    case reading
    case meditation
    case vitamins
    case sleep
    case healthy
    case journal

    var icon: String {
        switch self {
        case .water: return "drop.fill"
        case .exercise: return "figure.walk"
        case .reading: return "book.fill"
        case .meditation: return "brain.head.profile"
        case .vitamins: return "pill.fill"
        case .sleep: return "bed.double.fill"
        case .healthy: return "leaf.fill"
        case .journal: return "pencil.line"
        }
    }
}

// MARK: - Mood
enum Mood: String, Codable, CaseIterable {
    case great
    case good
    case okay
    case bad
    case terrible

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .bad: return "😟"
        case .terrible: return "😢"
        }
    }

    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .bad: return "Bad"
        case .terrible: return "Terrible"
        }
    }
}

// MARK: - Day Plan
struct DayPlan: Codable {
    var date: Date
    var tasks: [TaskItem]
    var priorities: [PriorityItem]
    var hourlySlots: [HourlySlot]
    var completedHabits: Set<String>
    var selectedMood: String?
    var drawingData: Data? // PKDrawing encoded data
    var notes: String

    init(date: Date) {
        self.date = date
        self.tasks = (0..<8).map { _ in TaskItem() }
        self.priorities = (1...5).map { PriorityItem(number: $0) }
        self.hourlySlots = (7...23).map { HourlySlot(hour: $0) }
        self.completedHabits = []
        self.selectedMood = nil
        self.drawingData = nil
        self.notes = ""
    }
}

// MARK: - Calendar Event (for Google Calendar)
struct CalendarEvent: Identifiable, Codable {
    let id: String
    var title: String
    var startTime: Date
    var endTime: Date
    var colorHex: String?

    var startHour: Int {
        Calendar.current.component(.hour, from: startTime)
    }

    var endHour: Int {
        Calendar.current.component(.hour, from: endTime)
    }
}

// MARK: - Planner Store
class PlannerStore: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var currentPlan: DayPlan
    @Published var calendarEvents: [CalendarEvent] = []
    @Published var isDrawingMode: Bool = false

    var storageService: DataStorageService?

    init() {
        // Always start with today's date
        let today = Calendar.current.startOfDay(for: Date())
        self.selectedDate = today
        self.currentPlan = DayPlan(date: today)
        loadPlan(for: today)
    }

    var selectedYear: Int {
        Calendar.current.component(.year, from: selectedDate)
    }

    var selectedMonth: Int {
        Calendar.current.component(.month, from: selectedDate)
    }

    var selectedDay: Int {
        Calendar.current.component(.day, from: selectedDate)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: selectedDate)
    }

    var shortMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: selectedDate).uppercased()
    }

    func selectDate(_ date: Date) {
        savePlan()
        selectedDate = date
        loadPlan(for: date)
    }

    func selectMonth(_ month: Int) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        components.month = month
        // Clamp day to valid range for the new month
        if let day = components.day {
            let range = Calendar.current.range(of: .day, in: .month, for: Calendar.current.date(from: DateComponents(year: components.year, month: month))!)!
            components.day = min(day, range.upperBound - 1)
        }
        if let newDate = Calendar.current.date(from: components) {
            selectDate(newDate)
        }
    }

    func savePlan() {
        guard let storageService = storageService else {
            // Fallback to local storage if not set
            let fallback = DataStorageService()
            fallback.save(plan: currentPlan, for: selectedDate)
            return
        }
        storageService.save(plan: currentPlan, for: selectedDate)
    }

    func loadPlan(for date: Date) {
        guard let storageService = storageService else {
            // Fallback to local storage if not set
            let fallback = DataStorageService()
            if let plan = fallback.load(for: date) {
                currentPlan = plan
            } else {
                currentPlan = DayPlan(date: date)
            }
            return
        }
        
        if let plan = storageService.load(for: date) {
            currentPlan = plan
        } else {
            currentPlan = DayPlan(date: date)
        }
    }

    func toggleHabit(_ habit: HabitType) {
        if currentPlan.completedHabits.contains(habit.rawValue) {
            currentPlan.completedHabits.remove(habit.rawValue)
        } else {
            currentPlan.completedHabits.insert(habit.rawValue)
        }
        savePlan()
    }

    func selectMood(_ mood: Mood) {
        currentPlan.selectedMood = mood.rawValue
        savePlan()
    }

    func toggleTask(_ index: Int) {
        guard index < currentPlan.tasks.count else { return }
        currentPlan.tasks[index].isCompleted.toggle()
        savePlan()
        updateNotifications()
    }
    
    func addTask() {
        currentPlan.tasks.append(TaskItem())
        savePlan()
        updateNotifications()
    }
    
    func deleteTask(_ index: Int) {
        guard index < currentPlan.tasks.count else { return }
        currentPlan.tasks.remove(at: index)
        savePlan()
        updateNotifications()
    }

    func updateDrawing(_ data: Data) {
        currentPlan.drawingData = data
        savePlan()
    }
    
    private func updateNotifications() {
        NotificationService.shared.updateNotificationWithPendingTasks(tasks: currentPlan.tasks)
    }
}
