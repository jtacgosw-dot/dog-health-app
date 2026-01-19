import SwiftUI

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    if !notificationManager.isAuthorized {
                        authorizationCard
                    }
                    
                    mealRemindersSection
                    
                    walkRemindersSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.petlyDarkGreen)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 50))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Notification Settings")
                .font(.petlyTitle(24))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Set up reminders to keep your pet healthy and happy")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
    
    private var authorizationCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 30))
                .foregroundColor(.orange)
            
            Text("Notifications Disabled")
                .font(.petlyBodyMedium(16))
                .foregroundColor(.primary)
            
            Text("Enable notifications to receive meal and walk reminders for your pet.")
                .font(.petlyBody(14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                notificationManager.requestAuthorization()
            }) {
                Text("Enable Notifications")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.petlyDarkGreen)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
    }
    
    private var mealRemindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.petlyDarkGreen)
                Text("Meal Reminders")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
            }
            
            VStack(spacing: 0) {
                Toggle(isOn: $notificationManager.mealRemindersEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.petlyDarkGreen)
                        Text("Enable Meal Reminders")
                            .font(.petlyBody(14))
                    }
                }
                .tint(.petlyDarkGreen)
                .padding()
                                .onChange(of: notificationManager.mealRemindersEnabled) {
                                    notificationManager.saveSettings()
                                }
                
                if notificationManager.mealRemindersEnabled {
                    Divider()
                        .padding(.horizontal)
                    
                    DatePicker(selection: $notificationManager.breakfastTime, displayedComponents: .hourAndMinute) {
                        HStack {
                            Image(systemName: "sunrise.fill")
                                .foregroundColor(.orange)
                            Text("Breakfast")
                                .font(.petlyBody(14))
                        }
                    }
                    .padding()
                                        .onChange(of: notificationManager.breakfastTime) {
                                            notificationManager.saveSettings()
                                        }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    DatePicker(selection: $notificationManager.dinnerTime, displayedComponents: .hourAndMinute) {
                        HStack {
                            Image(systemName: "sunset.fill")
                                .foregroundColor(.purple)
                            Text("Dinner")
                                .font(.petlyBody(14))
                        }
                    }
                    .padding()
                                        .onChange(of: notificationManager.dinnerTime) {
                                            notificationManager.saveSettings()
                                        }
                }
            }
            .background(Color.petlyLightGreen)
            .cornerRadius(16)
        }
    }
    
    private var walkRemindersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundColor(.petlyDarkGreen)
                Text("Walk Reminders")
                    .font(.petlyBodyMedium(18))
                    .foregroundColor(.petlyDarkGreen)
            }
            
            VStack(spacing: 0) {
                Toggle(isOn: $notificationManager.walkRemindersEnabled) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.petlyDarkGreen)
                        Text("Enable Walk Reminders")
                            .font(.petlyBody(14))
                    }
                }
                .tint(.petlyDarkGreen)
                .padding()
                                .onChange(of: notificationManager.walkRemindersEnabled) {
                                    notificationManager.saveSettings()
                                }
                
                if notificationManager.walkRemindersEnabled {
                    Divider()
                        .padding(.horizontal)
                    
                    DatePicker(selection: $notificationManager.morningWalkTime, displayedComponents: .hourAndMinute) {
                        HStack {
                            Image(systemName: "sunrise.fill")
                                .foregroundColor(.orange)
                            Text("Morning Walk")
                                .font(.petlyBody(14))
                        }
                    }
                    .padding()
                                        .onChange(of: notificationManager.morningWalkTime) {
                                            notificationManager.saveSettings()
                                        }
                    
                    Divider()
                        .padding(.horizontal)
                    
                    DatePicker(selection: $notificationManager.eveningWalkTime, displayedComponents: .hourAndMinute) {
                        HStack {
                            Image(systemName: "sunset.fill")
                                .foregroundColor(.purple)
                            Text("Evening Walk")
                                .font(.petlyBody(14))
                        }
                    }
                    .padding()
                                        .onChange(of: notificationManager.eveningWalkTime) {
                                            notificationManager.saveSettings()
                                        }
                }
            }
            .background(Color.petlyLightGreen)
            .cornerRadius(16)
        }
    }
}

#Preview {
    NavigationView {
        NotificationSettingsView()
    }
}
