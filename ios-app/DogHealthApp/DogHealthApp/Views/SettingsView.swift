import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSignOutAlert = false
    
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
                                SettingsRow(icon: "bell.fill", title: "Notifications", subtitle: "Manage notifications")
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
                                    NavigationLink(destination: PaywallView()) {
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
                                SettingsRow(icon: "questionmark.circle.fill", title: "Help & FAQ", subtitle: "Get help")
                                SettingsRow(icon: "envelope.fill", title: "Contact Us", subtitle: "Send feedback")
                                SettingsRow(icon: "doc.text.fill", title: "Terms & Privacy", subtitle: "Legal information")
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

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
