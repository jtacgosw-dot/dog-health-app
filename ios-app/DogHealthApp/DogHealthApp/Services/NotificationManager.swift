import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var mealRemindersEnabled = false
    @Published var walkRemindersEnabled = false
    @Published var breakfastTime = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? Date()
    @Published var dinnerTime = Calendar.current.date(from: DateComponents(hour: 18, minute: 0)) ?? Date()
    @Published var morningWalkTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 30)) ?? Date()
    @Published var eveningWalkTime = Calendar.current.date(from: DateComponents(hour: 17, minute: 30)) ?? Date()
    
    private let userDefaults = UserDefaults.standard
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        loadSettings()
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if granted {
                    self?.scheduleAllNotifications()
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        if mealRemindersEnabled {
            scheduleMealReminders()
        }
        
        if walkRemindersEnabled {
            scheduleWalkReminders()
        }
    }
    
    private func scheduleMealReminders() {
        scheduleNotification(
            identifier: "breakfast-reminder",
            title: "Breakfast Time!",
            body: "Time to feed your furry friend their morning meal",
            time: breakfastTime
        )
        
        scheduleNotification(
            identifier: "dinner-reminder",
            title: "Dinner Time!",
            body: "Don't forget to feed your pet their evening meal",
            time: dinnerTime
        )
    }
    
    private func scheduleWalkReminders() {
        scheduleNotification(
            identifier: "morning-walk-reminder",
            title: "Morning Walk Time!",
            body: "Your pet is ready for their morning walk",
            time: morningWalkTime
        )
        
        scheduleNotification(
            identifier: "evening-walk-reminder",
            title: "Evening Walk Time!",
            body: "Time for an evening stroll with your pet",
            time: eveningWalkTime
        )
    }
    
    private func scheduleNotification(identifier: String, title: String, body: String, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    func saveSettings() {
        userDefaults.set(mealRemindersEnabled, forKey: "mealRemindersEnabled")
        userDefaults.set(walkRemindersEnabled, forKey: "walkRemindersEnabled")
        userDefaults.set(breakfastTime, forKey: "breakfastTime")
        userDefaults.set(dinnerTime, forKey: "dinnerTime")
        userDefaults.set(morningWalkTime, forKey: "morningWalkTime")
        userDefaults.set(eveningWalkTime, forKey: "eveningWalkTime")
        
        scheduleAllNotifications()
    }
    
    private func loadSettings() {
        mealRemindersEnabled = userDefaults.bool(forKey: "mealRemindersEnabled")
        walkRemindersEnabled = userDefaults.bool(forKey: "walkRemindersEnabled")
        
        if let breakfast = userDefaults.object(forKey: "breakfastTime") as? Date {
            breakfastTime = breakfast
        }
        if let dinner = userDefaults.object(forKey: "dinnerTime") as? Date {
            dinnerTime = dinner
        }
        if let morningWalk = userDefaults.object(forKey: "morningWalkTime") as? Date {
            morningWalkTime = morningWalk
        }
        if let eveningWalk = userDefaults.object(forKey: "eveningWalkTime") as? Date {
            eveningWalkTime = eveningWalk
        }
    }
    
    func scheduleReminderNotification(for reminder: PetReminder) {
        guard reminder.isEnabled else { return }
        
        let content = UNMutableNotificationContent()
        content.title = reminderNotificationTitle(for: reminder)
        content.body = reminder.title
        content.sound = .default
        content.categoryIdentifier = "PET_REMINDER"
        content.userInfo = ["reminderId": reminder.id]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.nextDueDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pet-reminder-\(reminder.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling pet reminder notification: \(error)")
            }
        }
        
        if reminder.daysUntilDue > 1 {
            scheduleDayBeforeReminder(for: reminder)
        }
    }
    
    private func scheduleDayBeforeReminder(for reminder: PetReminder) {
        guard let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: reminder.nextDueDate) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Reminder Tomorrow"
        content.body = "\(reminder.title) is due tomorrow"
        content.sound = .default
        content.userInfo = ["reminderId": reminder.id]
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "pet-reminder-dayBefore-\(reminder.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling day-before reminder: \(error)")
            }
        }
    }
    
    private func reminderNotificationTitle(for reminder: PetReminder) -> String {
        switch reminder.type {
        case .vaccination:
            return "Vaccination Due"
        case .medication:
            return "Medication Reminder"
        case .fleaTick:
            return "Flea & Tick Treatment Due"
        case .heartworm:
            return "Heartworm Prevention Due"
        case .grooming:
            return "Grooming Appointment"
        case .vetAppointment:
            return "Vet Appointment"
        case .other:
            return "Pet Reminder"
        }
    }
    
    func cancelReminderNotification(for reminder: PetReminder) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "pet-reminder-\(reminder.id)",
            "pet-reminder-dayBefore-\(reminder.id)"
        ])
    }
    
    func rescheduleAllPetReminders(_ reminders: [PetReminder]) {
        for reminder in reminders where reminder.isEnabled {
            scheduleReminderNotification(for: reminder)
        }
    }
}
