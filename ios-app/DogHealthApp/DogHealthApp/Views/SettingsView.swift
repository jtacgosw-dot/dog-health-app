import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSignOutAlert = false
    @State private var showNotificationSettings = false
    @State private var showWeightTracking = false
    @State private var showPetReminders = false
    @State private var showVetSummary = false
    @State private var showHealthInsights = false
    @State private var showFeedbackSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyCream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        VStack(spacing: 20) {
                            SettingsSection(title: "Account") {
                                SettingsRow(icon: "person.fill", title: "Profile", subtitle: "Manage your account")
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
                                SettingsRow(icon: "creditcard.fill", title: "Manage Subscription", subtitle: "View billing details")
                            }
                            
                            SettingsSection(title: "Support") {
                                Button(action: openHelpCenter) {
                                    SettingsRow(icon: "questionmark.circle.fill", title: "Help & FAQ", subtitle: "Get help", showChevron: true)
                                }
                                Button(action: { showFeedbackSheet = true }) {
                                    SettingsRow(icon: "envelope.fill", title: "Send Feedback", subtitle: "Report issues or suggestions", showChevron: true)
                                }
                                Button(action: openLegalInfo) {
                                    SettingsRow(icon: "doc.text.fill", title: "Terms & Privacy", subtitle: "Legal information", showChevron: true)
                                }
                            }
                            
                            SettingsSection(title: "App") {
                                SettingsRow(icon: "info.circle.fill", title: "About", subtitle: "Version 1.0.0")
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
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.petlyDarkGreen)
                        Text("Settings")
                            .font(.headline)
                            .foregroundColor(.petlyDarkGreen)
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
            }
            .sheet(isPresented: $showWeightTracking) {
                NavigationView {
                    WeightTrackingView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showPetReminders) {
                NavigationView {
                    PetRemindersView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showVetSummary) {
                NavigationView {
                    VetSummaryExportView()
                        .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showHealthInsights) {
                HealthInsightsDashboardView()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showFeedbackSheet) {
                FeedbackView()
            }
        }
    }
    
    private func openHelpCenter() {
        if let url = URL(string: "https://petlyapp.com/help") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openLegalInfo() {
        if let url = URL(string: "https://petlyapp.com/legal") {
            UIApplication.shared.open(url)
        }
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
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.petlyDarkGreen)
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
                                .frame(minHeight: 150)
                                .padding(12)
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                                .scrollContentBackground(.hidden)
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
        // In a real app, this would send the feedback to a server
        // For now, we'll just show a success message
        showSuccessAlert = true
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
