import SwiftUI
import SwiftData
import StoreKit

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
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
    @State private var showProfileSheet = false
    @State private var exportURL: URL?
    @State private var isDeletingData = false
    @State private var deleteSuccessMessage: String?
    
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
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("General")
                                .font(.petlyTitle(28))
                                .foregroundColor(.petlyDarkGreen)
                            Text("Manage your app settings")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyFormIcon)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        VStack(spacing: 16) {
                            // Account Section
                            PetlySettingsSection(title: "Account") {
                                PetlySettingsButton(icon: "person.fill", title: "Profile", subtitle: appState.currentUser?.fullName ?? "Manage your account") {
                                    showProfileSheet = true
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "bell.fill", title: "Notifications", subtitle: "Manage reminders") {
                                    showNotificationSettings = true
                                }
                            }
                            
                            // Pet Health Section
                            PetlySettingsSection(title: "Pet Health") {
                                PetlySettingsButton(icon: "scalemass.fill", title: "Weight Tracking", subtitle: "Track your pet's weight") {
                                    showWeightTracking = true
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "calendar.badge.clock", title: "Pet Reminders", subtitle: "Vaccinations, medications & more") {
                                    showPetReminders = true
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "doc.text.fill", title: "Vet Visit Summary", subtitle: "Export health logs as PDF") {
                                    showVetSummary = true
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "chart.bar.fill", title: "Health Insights", subtitle: "View trends and analytics") {
                                    showHealthInsights = true
                                }
                            }
                            
                            // Subscription Section
                            PetlySettingsSection(title: "Subscription") {
                                if appState.hasActiveSubscription {
                                    PetlySettingsRow(icon: "crown.fill", title: "Petly Premium", subtitle: "Active subscription", badge: "Active")
                                } else {
                                    NavigationLink(destination: NewPaywallView()) {
                                        PetlySettingsRow(icon: "crown.fill", title: "Upgrade to Premium", subtitle: "Unlock all features", showChevron: true)
                                    }
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "creditcard.fill", title: "Manage Subscription", subtitle: "View billing details") {
                                    openSubscriptionManagement()
                                }
                            }
                            
                            // Data & Privacy Section
                            PetlySettingsSection(title: "Data & Privacy") {
                                PetlySettingsButton(icon: "square.and.arrow.up.fill", title: "Export Data", subtitle: "Download all your pet's data") {
                                    exportAllData()
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "trash.fill", title: "Delete All Data", subtitle: "Remove all health logs", iconColor: .red) {
                                    showDeleteDataAlert = true
                                }
                            }
                            
                            // Support Section
                            PetlySettingsSection(title: "Support") {
                                PetlySettingsButton(icon: "questionmark.circle.fill", title: "Help & FAQ", subtitle: "Get help") {
                                    openHelpCenter()
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "envelope.fill", title: "Send Feedback", subtitle: "Report issues or suggestions") {
                                    showFeedbackSheet = true
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "star.fill", title: "Rate Petly", subtitle: "Love the app? Leave a review!") {
                                    rateApp()
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "square.and.arrow.up", title: "Share Petly", subtitle: "Tell your friends about us") {
                                    shareApp()
                                }
                            }
                            
                            // Legal Section
                            PetlySettingsSection(title: "Legal") {
                                PetlySettingsButton(icon: "hand.raised.fill", title: "Privacy Policy", subtitle: "How we protect your data") {
                                    openPrivacyPolicy()
                                }
                                PetlySettingsDivider()
                                PetlySettingsButton(icon: "doc.text.fill", title: "Terms of Service", subtitle: "Usage terms") {
                                    openTermsOfService()
                                }
                            }
                            
                            // About Section
                            PetlySettingsSection(title: "About") {
                                PetlySettingsButton(icon: "info.circle.fill", title: "About Petly", subtitle: "Version \(appVersion) (\(buildNumber))") {
                                    showAboutSheet = true
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Sign Out Button
                        Button(action: { showSignOutAlert = true }) {
                            HStack(spacing: 10) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 18))
                                Text("Sign Out")
                                    .font(.petlyBodyMedium(16))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Footer
                        VStack(spacing: 4) {
                            Text("Made with love for pet parents")
                                .font(.petlyBody(12))
                                .foregroundColor(.petlyFormIcon)
                            Text("Version \(appVersion)")
                                .font(.petlyBody(11))
                                .foregroundColor(.petlyFormIcon.opacity(0.7))
                        }
                        .padding(.vertical, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.petlyDarkGreen)
                            .padding(8)
                            .background(Color.petlyLightGreen)
                            .clipShape(Circle())
                    }
                }
            }
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
            .sheet(isPresented: $showProfileSheet) {
                ProfileEditView()
                    .environmentObject(appState)
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
        .preferredColorScheme(.light)
    }
    
    private func openHelpCenter(){
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
        .preferredColorScheme(.light)
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
        .preferredColorScheme(.light)
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

struct ProfileEditView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Name")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                        
                        TextField("Enter your name", text: $name)
                            .font(.petlyBody(16))
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Text("This name will be used to personalize your experience throughout the app.")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    Button(action: saveProfile) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Changes")
                                .font(.petlyBodyMedium(16))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(25)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .onAppear {
            // Pre-fill with existing name
            if let existingName = appState.currentUser?.fullName {
                name = existingName
            } else if let savedName = UserDefaults.standard.string(forKey: "ownerName") {
                name = savedName
            }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        // Update the user's name
        if var user = appState.currentUser {
            user.fullName = name.isEmpty ? nil : name
            appState.currentUser = user
        }
        
        // Save to UserDefaults for persistence
        if name.isEmpty {
            UserDefaults.standard.removeObject(forKey: "ownerName")
        } else {
            UserDefaults.standard.set(name, forKey: "ownerName")
        }
        
        isSaving = false
        dismiss()
    }
}

// MARK: - Petly Themed Settings Components

struct PetlySettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.petlyBody(12))
                .fontWeight(.semibold)
                .foregroundColor(.petlyFormIcon)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.petlyLightGreen)
            .cornerRadius(16)
        }
    }
}

struct PetlySettingsButton: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = .petlyDarkGreen
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            PetlySettingsRow(icon: icon, title: title, subtitle: subtitle, iconColor: iconColor, showChevron: true)
        }
    }
}

struct PetlySettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var badge: String? = nil
    var iconColor: Color = .petlyDarkGreen
    var showChevron: Bool = false
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.petlyBody(16))
                    .fontWeight(.medium)
                    .foregroundColor(.petlyDarkGreen)
                Text(subtitle)
                    .font(.petlyBody(13))
                    .foregroundColor(.petlyFormIcon)
            }
            
            Spacer()
            
            if let badge = badge {
                Text(badge)
                    .font(.petlyBody(11))
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.petlyDarkGreen)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.petlyFormIcon.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

struct PetlySettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.petlyDarkGreen.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 70)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
