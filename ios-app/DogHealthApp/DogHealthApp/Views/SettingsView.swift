import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Query private var healthLogs: [HealthLogEntry]
    @Query private var reminders: [PetReminder]
    @Query private var carePlans: [CarePlan]
    @State private var showSignOutAlert = false
    @State private var showNotificationSettings = false
    @State private var showWeightTracking = false
    @State private var showPetReminders = false
    @State private var showVetSummary = false
    @State private var showHealthInsights = false
    @State private var showFeedbackSheet = false
    @State private var showDeleteDataAlert = false
    @State private var showAboutSheet = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var isDeletingData = false
    @State private var deleteSuccessMessage: String?
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        VStack(spacing: 20) {
                            SettingsSection(title: "Account") {
                                SettingsRow(icon: "person.fill", title: "Profile", subtitle: appState.currentUser?.fullName ?? "Manage your account")
                                Button(action: { showNotificationSettings = true }) {
                                    SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage reminders", showChevron: true)
                                }
                            }
                            
                            SettingsSection(title: "Pet Health") {
                                Button(action: { showWeightTracking = true }) {
                                    SettingsRow(icon: "scalemass.fill", title: "Weight Tracking", subtitle: "Track your pet's weight", showChevron: true)
                                }
                                Button(action: { showPetReminders = true }) {
                                    SettingsRow(icon: "calendar.badge.clock", title: "Pet Reminders", subtitle: "Vaccinations, medications & more", showChevron: true)
                                }
                                Button(action: { showVetSummary = true }) {
                                    SettingsRow(icon: "doc.text.fill", title: "Vet Visit Summary", subtitle: "Export health logs as PDF", showChevron: true)
                                }
                                Button(action: { showHealthInsights = true }) {
                                    SettingsRow(icon: "chart.bar.fill", title: "Health Insights", subtitle: "View trends and analytics", showChevron: true)
                                }
                            }
                            
                            SettingsSection(title: "Appearance") {
                                VStack(spacing: 0) {
                                    SettingsRow(icon: "paintbrush.fill", title: "Theme", subtitle: appearanceModeText)
                                    
                                    Picker("Appearance", selection: $appearanceMode) {
                                        Text("System").tag(0)
                                        Text("Light").tag(1)
                                        Text("Dark").tag(2)
                                    }
                                    .pickerStyle(.segmented)
                                    .padding(.horizontal)
                                    .padding(.bottom, 12)
                                }
                            }
                            
                            SettingsSection(title: "Subscription") {
                                if appState.hasActiveSubscription {
                                    SettingsRow(
                                        icon: "crown.fill",
                                        title: "Petly Premium",
                                        subtitle: "Active subscription",
                                        badge: "Active"
                                    )
                                } else {
                                    NavigationLink(destination: NewPaywallView()) {
                                        SettingsRow(
                                            icon: "crown.fill",
                                            title: "Upgrade to Premium",
                                            subtitle: "Unlock all features",
                                            showChevron: true
                                        )
                                    }
                                }
                                Button(action: openSubscriptionManagement) {
                                    SettingsRow(icon: "creditcard.fill", title: "Manage Subscription", subtitle: "View billing details", showChevron: true)
                                }
                            }
                            
                            SettingsSection(title: "Data & Privacy") {
                                Button(action: exportAllData) {
                                    SettingsRow(icon: "square.and.arrow.up.fill", title: "Export Data", subtitle: "Download all your pet's data", showChevron: true)
                                }
                                Button(action: { showDeleteDataAlert = true }) {
                                    SettingsRow(icon: "trash.fill", title: "Delete All Data", subtitle: "Remove all health logs", iconColor: .red)
                                }
                            }
                            
                            SettingsSection(title: "Support") {
                                Button(action: openHelpCenter) {
                                    SettingsRow(icon: "questionmark.circle.fill", title: "Help & FAQ", subtitle: "Get help", showChevron: true)
                                }
                                Button(action: { showFeedbackSheet = true }) {
                                    SettingsRow(icon: "envelope.fill", title: "Send Feedback", subtitle: "Report issues or suggestions", showChevron: true)
                                }
                                Button(action: rateApp) {
                                    SettingsRow(icon: "star.fill", title: "Rate Petly", subtitle: "Love the app? Leave a review!", showChevron: true)
                                }
                                Button(action: shareApp) {
                                    SettingsRow(icon: "square.and.arrow.up", title: "Share Petly", subtitle: "Tell your friends about us", showChevron: true)
                                }
                            }
                            
                            SettingsSection(title: "Legal") {
                                Button(action: openPrivacyPolicy) {
                                    SettingsRow(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "How we protect your data", showChevron: true)
                                }
                                Button(action: openTermsOfService) {
                                    SettingsRow(icon: "doc.text.fill", title: "Terms of Service", subtitle: "Usage terms", showChevron: true)
                                }
                            }
                            
                            SettingsSection(title: "About") {
                                Button(action: { showAboutSheet = true }) {
                                    SettingsRow(icon: "info.circle.fill", title: "About Petly", subtitle: "Version \(appVersion) (\(buildNumber))", showChevron: true)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        Button(action: { showSignOutAlert = true }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        Text("Made with love for pet parents everywhere")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    appState.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .sheet(isPresented: $showNotificationSettings) {
                NavigationView {
                    NotificationSettingsView()
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showWeightTracking) {
                NavigationView {
                    WeightTrackingView()
                        .environmentObject(appState)
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showPetReminders) {
                NavigationView {
                    PetRemindersView()
                        .environmentObject(appState)
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showVetSummary) {
                NavigationView {
                    VetSummaryExportView()
                        .environmentObject(appState)
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showHealthInsights) {
                HealthInsightsDashboardView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackView()
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showAboutSheet) {
                AboutView()
                    .buttonStyle(.plain)
            }
            .alert("Delete All Data", isPresented: $showDeleteDataAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all health logs and data for your pets. This action cannot be undone.")
            }
            .sheet(isPresented: $showExportSheet) {
                if let url = exportURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private var appearanceModeText:String {
        switch appearanceMode {
        case 1: return "Light"
        case 2: return "Dark"
        default: return "System"
        }
    }
    
    private func openHelpCenter() {
        if let url = URL(string: "https://petlyapp.com/help") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openPrivacyPolicy() {
        if let url = URL(string: "https://petlyapp.com/privacy") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openTermsOfService() {
        if let url = URL(string: "https://petlyapp.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openSubscriptionManagement() {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }
    
    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    private func shareApp() {
        let appStoreURL = URL(string: "https://apps.apple.com/app/petly")!
        let activityVC = UIActivityViewController(
            activityItems: ["Check out Petly - the best app for tracking your pet's health!", appStoreURL],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func exportAllData() {
        guard let dogId = appState.currentDog?.id else { return }
        
        let dogLogs = healthLogs.filter { $0.dogId == dogId }
        let dogReminders = reminders.filter { $0.dogId == dogId }
        
        var exportData: [[String: Any]] = []
        
        let dateFormatter = ISO8601DateFormatter()
        
        for log in dogLogs {
            var logDict: [String: Any] = [
                "type": "health_log",
                "logType": log.logType,
                "timestamp": dateFormatter.string(from: log.timestamp),
                "notes": log.notes
            ]
            if let mealType = log.mealType { logDict["mealType"] = mealType }
            if let amount = log.amount { logDict["amount"] = amount }
            if let duration = log.duration { logDict["duration"] = duration }
            if let moodLevel = log.moodLevel { logDict["moodLevel"] = moodLevel }
            if let symptomType = log.symptomType { logDict["symptomType"] = symptomType }
            if let severityLevel = log.severityLevel { logDict["severityLevel"] = severityLevel }
            exportData.append(logDict)
        }
        
        for reminder in dogReminders {
            exportData.append([
                "type": "reminder",
                "title": reminder.title,
                "reminderType": reminder.reminderType,
                "frequency": reminder.frequency,
                "nextDueDate": dateFormatter.string(from: reminder.nextDueDate),
                "notes": reminder.notes ?? ""
            ])
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("petly_export_\(Date().timeIntervalSince1970).json")
            try jsonData.write(to: tempURL)
            exportURL = tempURL
            showExportSheet = true
        } catch {
            print("Export failed: \(error)")
        }
    }
    
    private func deleteAllData() {
        guard let dogId = appState.currentDog?.id else { return }
        
        let dogLogs = healthLogs.filter { $0.dogId == dogId }
        let dogReminders = reminders.filter { $0.dogId == dogId }
        let dogCarePlans = carePlans.filter { $0.dogId == dogId }
        
        for log in dogLogs {
            modelContext.delete(log)
        }
        
        for reminder in dogReminders {
            NotificationManager.shared.cancelReminderNotification(for: reminder)
            modelContext.delete(reminder)
        }
        
        for plan in dogCarePlans {
            modelContext.delete(plan)
        }
        
        try? modelContext.save()
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.petlySageGreen.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var badge: String? = nil
    var showChevron: Bool = false
    var iconColor: Color = .petlyDarkGreen
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.petlyDarkGreen.opacity(0.1))
                    .foregroundColor(.petlyDarkGreen)
                    .cornerRadius(8)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .contentShape(Rectangle())
    }
}

struct FeedbackView: View {
    @Environment(\.dismiss) var dismiss
    @State private var feedbackType: FeedbackType = .suggestion
    @State private var feedbackText: String = ""
    @State private var email: String = ""
    @State private var showSuccessAlert = false
    @State private var isSubmitting = false
    @State private var showMailError = false
    
    enum FeedbackType: String, CaseIterable {
        case bug = "Bug Report"
        case suggestion = "Suggestion"
        case question = "Question"
        case other = "Other"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feedback Type")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            HStack(spacing: 8) {
                                ForEach(FeedbackType.allCases, id: \.self) { type in
                                    Button(action: { feedbackType = type }) {
                                        Text(type.rawValue)
                                            .font(.petlyBody(12))
                                            .foregroundColor(feedbackType == type ? .white : .petlyDarkGreen)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(feedbackType == type ? Color.petlyDarkGreen : Color.petlyLightGreen)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Email (optional)")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("email@example.com", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .textFieldStyle(PetlyTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Feedback")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextEditor(text: $feedbackText)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.petlyDarkGreen)
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        Button(action: submitFeedback) {
                            Text("SUBMIT FEEDBACK")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(feedbackText.isEmpty ? Color.gray : Color.petlyDarkGreen)
                                .cornerRadius(25)
                        }
                        .disabled(feedbackText.isEmpty)
                        .padding(.top, 10)
                        
                        Text("We read every piece of feedback and use it to improve Petly. Thank you for helping us make the app better!")
                            .font(.petlyBody(12))
                            .foregroundColor(.petlyFormIcon)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)
                    }
                    .padding()
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle("Send Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .alert("Thank You!", isPresented: $showSuccessAlert) {
                Button("OK") { dismiss() }
            } message: {
                Text("Your feedback has been submitted. We appreciate you taking the time to help us improve Petly!")
            }
        }
    }
    
    private func submitFeedback() {
        let subject = "Petly Feedback: \(feedbackType.rawValue)"
        let body = """
        Feedback Type: \(feedbackType.rawValue)
        
        \(feedbackText)
        
        ---
        Reply Email: \(email.isEmpty ? "Not provided" : email)
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        """
        
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: "mailto:feedback@petlyapp.com?subject=\(encodedSubject)&body=\(encodedBody)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
                showSuccessAlert = true
            } else {
                UserDefaults.standard.set([
                    "type": feedbackType.rawValue,
                    "text": feedbackText,
                    "email": email,
                    "date": ISO8601DateFormatter().string(from: Date())
                ], forKey: "pendingFeedback_\(Date().timeIntervalSince1970)")
                showSuccessAlert = true
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.petlyLightGreen, Color.petlyDarkGreen.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.petlyDarkGreen)
                            }
                            
                            Text("Petly")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.petlyDarkGreen)
                            
                            Text("Your Pet's Health Companion")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text("Version \(appVersion) (\(buildNumber))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About Petly")
                                .font(.headline)
                                .foregroundColor(.petlyDarkGreen)
                            
                            Text("Petly helps you track and manage your pet's health with ease. Log meals, activities, symptoms, and more to keep your furry friend healthy and happy.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("Our AI-powered insights help you understand patterns in your pet's health and provide personalized recommendations based on their unique needs.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Features")
                                .font(.headline)
                                .foregroundColor(.petlyDarkGreen)
                            
                            FeatureRow(icon: "heart.text.square", title: "Health Logging", description: "Track meals, activities, symptoms & mood")
                            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Smart Insights", description: "AI-powered health pattern detection")
                            FeatureRow(icon: "calendar.badge.clock", title: "Reminders", description: "Never miss vaccinations or medications")
                            FeatureRow(icon: "message.fill", title: "AI Chat", description: "Get instant answers about pet health")
                            FeatureRow(icon: "doc.text.fill", title: "Vet Reports", description: "Share health records with your vet")
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        VStack(spacing: 8) {
                            Text("Made with love for pet parents")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("2024 Petly. All rights reserved.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 30)
                    }
                    .padding()
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
