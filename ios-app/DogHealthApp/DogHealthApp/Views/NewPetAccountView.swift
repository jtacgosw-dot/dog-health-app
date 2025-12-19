import SwiftUI

struct NewPetAccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var scrollOffset: CGFloat = 0
    @State private var showingNutrition = false
    @State private var showingPersonality = false
    @State private var showingHealthConcerns = false
    @State private var showingWeight = false
    @State private var showingGeneral = false
    @State private var showingMembership = false
    @State private var showingInviteFriends = false
    @State private var showingCustomerSupport = false
    
    private let expandedAvatarSize: CGFloat = 120
    private let collapsedAvatarSize: CGFloat = 40
    private let collapseThreshold: CGFloat = 150
    
    var collapseProgress: CGFloat {
        min(max(scrollOffset / collapseThreshold, 0), 1)
    }
    
    var avatarSize: CGFloat {
        expandedAvatarSize - (collapseProgress * (expandedAvatarSize - collapsedAvatarSize))
    }
    
    var titleOpacity: Double {
        max(0, 1 - Double(collapseProgress * 1.5))
    }
    
    var headerOffset: CGFloat {
        -scrollOffset * 0.5
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    Color.clear
                        .frame(height: 1)
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .global).minY
                                )
                            }
                        )
                    
                    Button(action: { showingInviteFriends = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.petlyDarkGreen)
                                .frame(width: 24)
                            
                            Text("Invite Friends")
                                .font(.petlyBody(16))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.petlyFormIcon)
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PetlyButtonStyle())
                    
                    Button(action: { showingCustomerSupport = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "headphones")
                                .font(.system(size: 20))
                                .foregroundColor(.petlyDarkGreen)
                                .frame(width: 24)
                            
                            Text("Customer Support")
                                .font(.petlyBody(16))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.petlyFormIcon)
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PetlyButtonStyle())
                    
                    VStack(spacing: 0) {
                        AccountMenuButton(icon: "fork.knife", title: "Nutrition") {
                            showingNutrition = true
                        }
                        AccountMenuButton(icon: "pawprint.fill", title: "Personality") {
                            showingPersonality = true
                        }
                        AccountMenuButton(icon: "heart.fill", title: "Health Concerns") {
                            showingHealthConcerns = true
                        }
                        AccountMenuButton(icon: "scalemass", title: "Weight") {
                            showingWeight = true
                        }
                        AccountMenuButton(icon: "gearshape.fill", title: "General") {
                            showingGeneral = true
                        }
                        AccountMenuButton(icon: "sparkles", title: "Membership", isLast: true) {
                            showingMembership = true
                        }
                    }
                    .background(Color.petlyLightGreen)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 280)
                .padding(.bottom, 100)
            }
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                let initialOffset: CGFloat = 280
                scrollOffset = max(0, initialOffset - value + 47)
            }
            .sheet(isPresented: $showingNutrition) {
                AccountDetailView(title: "Nutrition", icon: "fork.knife", description: "Manage your pet's dietary preferences and meal plans.")
            }
            .sheet(isPresented: $showingPersonality) {
                AccountDetailView(title: "Personality", icon: "pawprint.fill", description: "Track your pet's personality traits and behaviors.")
            }
            .sheet(isPresented: $showingHealthConcerns) {
                AccountDetailView(title: "Health Concerns", icon: "heart.fill", description: "Monitor and manage your pet's health conditions.")
            }
            .sheet(isPresented: $showingWeight) {
                WeightTrackingView()
            }
            .sheet(isPresented: $showingGeneral) {
                SettingsView()
            }
            .sheet(isPresented: $showingMembership) {
                NewPaywallView()
            }
            .sheet(isPresented: $showingInviteFriends) {
                AccountDetailView(title: "Invite Friends", icon: "person.2.fill", description: "Share Petly with friends and family to help them care for their pets too!")
            }
            .sheet(isPresented: $showingCustomerSupport) {
                AccountDetailView(title: "Customer Support", icon: "headphones", description: "Need help? Our support team is here for you 24/7.")
            }
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.petlyDarkGreen)
                            .padding()
                            .background(Color.petlyLightGreen)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    if collapseProgress > 0.7 {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "dog.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.petlyDarkGreen)
                                )
                            
                            Text("\(appState.currentDog?.name ?? "Arlo")")
                                .font(.petlyTitle(18))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .opacity(Double((collapseProgress - 0.7) * 3.33))
                        .transition(.opacity)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                VStack(spacing: 8) {
                    Text("Pet Account")
                        .font(.petlyTitle(28))
                        .foregroundColor(.petlyDarkGreen)
                        .opacity(titleOpacity)
                    
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: avatarSize, height: avatarSize)
                        .overlay(
                            Image(systemName: "dog.fill")
                                .font(.system(size: avatarSize * 0.5))
                                .foregroundColor(.petlyDarkGreen)
                        )
                        .overlay(
                            Circle()
                                .fill(Color.petlyDarkGreen)
                                .frame(width: avatarSize * 0.3, height: avatarSize * 0.3)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: avatarSize * 0.12))
                                        .foregroundColor(.white)
                                )
                                .offset(x: avatarSize * 0.33, y: avatarSize * 0.33)
                                .opacity(titleOpacity)
                        )
                    
                    Text("\(appState.currentDog?.name ?? "Arlo"), \(appState.currentDog?.age ?? 1) Year")
                        .font(.petlyTitle(24))
                        .foregroundColor(.petlyDarkGreen)
                        .opacity(titleOpacity)
                    
                    Text("Breed: \(appState.currentDog?.breed ?? "Mini Poodle")")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                        .opacity(titleOpacity)
                }
                .padding(.bottom, 12)
                .offset(y: headerOffset)
                
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(
                Color.petlyBackground
                    .frame(height: max(60, 280 - scrollOffset))
                    .frame(maxHeight: .infinity, alignment: .top)
            )
            .clipped()
        }
        .animation(.easeOut(duration: 0.1), value: collapseProgress)
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct AccountMenuButton: View {
    let icon: String
    let title: String
    var isLast: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.petlyDarkGreen)
                    .frame(width: 24)
                
                Text(title)
                    .font(.petlyBody(16))
                    .foregroundColor(.petlyDarkGreen)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.petlyFormIcon)
                    .font(.system(size: 14))
            }
            .padding()
            .background(Color.petlyLightGreen)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .overlay(
            Group {
                if !isLast {
                    Rectangle()
                        .fill(Color.petlyDarkGreen.opacity(0.1))
                        .frame(height: 1)
                        .padding(.leading, 60)
                }
            },
            alignment: .bottom
        )
    }
}

struct AccountDetailView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: 40))
                                .foregroundColor(.petlyDarkGreen)
                        )
                    
                    Text(title)
                        .font(.petlyTitle(28))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text(description)
                        .font(.petlyBody(16))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Text("Coming Soon")
                        .font(.petlyBodyMedium(14))
                        .foregroundColor(.petlyFormIcon)
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(12)
                    
                    Spacer()
                }
                .padding(.top, 40)
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
        }
    }
}

#Preview {
    NewPetAccountView()
        .environmentObject(AppState())
}
