import SwiftUI

struct NewMainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showDailyLog = false
    @State private var chatPrompt: String = ""
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    HomeDashboardView()
                case 1:
                    NewChatView(initialPrompt: $chatPrompt)
                case 2:
                    HomeDashboardView()
                case 3:
                    ExploreView(onQuickAction: { prompt in
                        chatPrompt = prompt
                        withAnimation {
                            selectedTab = 1
                        }
                    })
                case 4:
                    NewPetAccountView()
                default:
                    HomeDashboardView()
                }
            }
            
            CustomTabBar(selectedTab: $selectedTab, showDailyLog: $showDailyLog)
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showDailyLog) {
            DailyLogEntryView()
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showDailyLog: Bool
    @State private var centerButtonPressed = false
    
    let tabs = [
        ("house.fill", "Home"),
        ("message.fill", "Chat"),
        ("", ""),
        ("globe", "Explore"),
        ("person.fill", "Account")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                if index == 2 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            centerButtonPressed = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                centerButtonPressed = false
                            }
                            showDailyLog = true
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .offset(y: -20)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(centerButtonPressed ? 0.9 : 1.0)
                    .frame(maxWidth: .infinity)
                } else {
                    TabBarButton(
                        icon: tabs[index].0,
                        title: tabs[index].1,
                        isSelected: selectedTab == index
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            Color.petlyDarkGreen
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    @State private var bounceScale: CGFloat = 1.0
    
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
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .petlyLightGreen : .petlyFormIcon)
                    .scaleEffect(bounceScale)
                
                Text(title)
                    .font(.petlyBody(10))
                    .foregroundColor(isSelected ? .petlyLightGreen : .petlyFormIcon)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                    bounceScale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                        bounceScale = 1.0
                    }
                }
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
}

struct ExploreView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedQuickAction: String?
    var onQuickAction: ((String) -> Void)?
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    let quickActions = [
        ("stethoscope", "Check symptoms for my dog"),
        ("fork.knife", "Picky eater help"),
        ("brain.head.profile", "Anxious dog tips"),
        ("pawprint", "Itchy paws"),
        ("carrot", "New food intro")
    ]
    
    let articles = [
        ("dog.fill", "Dry vs. Fresh vs. Raw: Which Diet Is Right for Your Pet?"),
        ("allergens", "The Truth About Hidden Pet Allergies"),
        ("heart.text.square", "Understanding Your Pet's Emotional Needs")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AI Assistant")
                                .font(.petlyBody(12))
                                .foregroundColor(.petlyFormIcon)
                            
                            Text("Ready to care for your")
                                .font(.petlyTitle(24))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Text("pet's wellbeing?")
                                .font(.petlyTitle(24))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color.petlyLightGreen)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Image(systemName: "dog.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.petlyDarkGreen)
                            )
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(quickActions, id: \.1) { icon, title in
                                QuickActionChip(icon: icon, title: title) {
                                    onQuickAction?(title)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Start Exploring")
                        .font(.petlyTitle(20))
                        .foregroundColor(.petlyDarkGreen)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(articles, id: \.1) { icon, title in
                                ArticleCard(icon: icon, title: title)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Insights")
                        .font(.petlyTitle(20))
                        .foregroundColor(.petlyDarkGreen)
                        .padding(.horizontal)
                    
                    InsightCard(
                        icon: "pills",
                        title: "Give \(dogName) Daily Multivitamins",
                        description: "\(dogName) would benefit from daily Multivitamins—perfect for joints, coat, and immunity."
                    )
                    .padding(.horizontal)
                    
                    Text("Petly Suggestion")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(Color.petlyBackground)
        }
        .background(Color.petlyBackground.ignoresSafeArea())
    }
}

struct QuickActionChip: View {
    let icon: String
    let title: String
    var action: () -> Void = {}
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.petlyDarkGreen)
                
                Text(title)
                    .font(.petlyBody(13))
                    .foregroundColor(.petlyDarkGreen)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.petlyLightGreen)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

struct ArticleCard: View {
    let icon: String
    let title: String
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
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.petlyLightGreen)
                    .frame(width: 240, height: 140)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 48))
                            .foregroundColor(.petlyDarkGreen.opacity(0.3))
                    )
                
                Text(title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                    .multilineTextAlignment(.leading)
                    .frame(width: 240, alignment: .leading)
                    .lineLimit(2)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let description: String
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
            }
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.petlyDarkGreen)
                        .multilineTextAlignment(.leading)
                    
                    Text(description)
                        .font(.petlyBody(13))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.petlyDarkGreen.opacity(0.3))
            }
            .padding()
            .background(Color.petlyLightGreen)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

#Preview {
    NewMainTabView()
        .environmentObject(AppState())
}
