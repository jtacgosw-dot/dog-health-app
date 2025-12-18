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
}
