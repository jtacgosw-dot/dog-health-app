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
                .buttonStyle(.plain)
        }
        .buttonStyle(.plain)
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Binding var showDailyLog: Bool
    @State private var centerButtonPressed = false
    
    // Scaled sizes for Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var centerButtonSize: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var centerIconSize: CGFloat = 28
    
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
                                .frame(width: min(centerButtonSize, 80), height: min(centerButtonSize, 80))
                            
                            Image(systemName: "plus")
                                .font(.system(size: min(centerIconSize, 36), weight: .medium))
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
    
    // Scaled sizes for Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var tabIconSize: CGFloat = 20
    
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
                    .font(.system(size: min(tabIconSize, 28)))
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
    @State private var petPhotoData: Data?
    var onQuickAction: ((String) -> Void)?
    
    // Scaled sizes for Dynamic Type support
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 60
    @ScaledMetric(relativeTo: .body) private var avatarIconSize: CGFloat = 28
    
    private var dogName: String {
        appState.currentDog?.name ?? "your pet"
    }
    
    let quickActions = [
        ("stethoscope", "What symptoms should I watch for?"),
        ("fork.knife", "Why won't my dog eat?"),
        ("brain.head.profile", "How can I calm my anxious dog?"),
        ("pawprint", "Why is my dog scratching so much?"),
        ("carrot", "How do I introduce new food safely?")
    ]
    
    let articles: [(icon: String, title: String, category: String, color: Color)] = [
        ("fork.knife.circle.fill", "Dry vs. Fresh vs. Raw: Which Diet Is Right for Your Pet?", "Nutrition", Color.orange),
        ("allergens", "The Truth About Hidden Pet Allergies", "Health", Color.red),
        ("heart.text.square.fill", "Understanding Your Pet's Emotional Needs", "Wellness", Color.pink),
        ("figure.walk", "Exercise Guidelines for Every Dog Breed", "Fitness", Color.green),
        ("moon.stars.fill", "How Much Sleep Does Your Dog Really Need?", "Sleep", Color.indigo),
        ("drop.fill", "Signs of Dehydration in Dogs", "Health", Color.blue)
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
                        
                        if let photoData = petPhotoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: min(avatarSize, 80), height: min(avatarSize, 80))
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: min(avatarSize, 80), height: min(avatarSize, 80))
                                .overlay(
                                    Image(systemName: "dog.fill")
                                        .font(.system(size: min(avatarIconSize, 36)))
                                        .foregroundColor(.petlyDarkGreen)
                                )
                        }
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
                            ForEach(articles, id: \.title) { article in
                                ArticleCard(icon: article.icon, title: article.title, category: article.category, accentColor: article.color)
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
                .padding(.bottom, 100)
            }
            .background(Color.petlyBackground)
        }
        .background(Color.petlyBackground.ignoresSafeArea())
        .onAppear {
            loadPetPhoto()
        }
        .onChange(of: appState.currentDog?.id) { _, _ in
            loadPetPhoto()
        }
    }
    
    private func loadPetPhoto() {
        guard let dogId = appState.currentDog?.id else { return }
        let key = "petPhoto_\(dogId)"
        petPhotoData = UserDefaults.standard.data(forKey: key)
    }
}

struct QuickActionChip: View {
    let icon: String
    let title: String
    var action: () -> Void = {}
    @State private var isPressed = false
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 14
    
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
                    .font(.system(size: iconSize))
                    .foregroundColor(.petlyDarkGreen)
                
                Text(title)
                    .font(.petlyBody(13))
                    .foregroundColor(.petlyDarkGreen)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)
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
    var category: String = ""
    var accentColor: Color = .petlyDarkGreen
    @State private var isPressed = false
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 48
    @ScaledMetric(relativeTo: .body) private var cardWidth: CGFloat = 240
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 140
    
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
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [accentColor.opacity(0.3), accentColor.opacity(0.1)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: cardWidth, height: cardHeight)
                        .overlay(
                            Image(systemName: icon)
                                .font(.system(size: iconSize))
                                .foregroundColor(accentColor.opacity(0.5))
                        )
                    
                    if !category.isEmpty {
                        Text(category)
                            .font(.petlyBody(10))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(accentColor.opacity(0.8))
                            .cornerRadius(8)
                            .padding(8)
                    }
                }
                
                Text(title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                    .multilineTextAlignment(.leading)
                    .frame(width: cardWidth, alignment: .leading)
                    .lineLimit(nil)
                    .minimumScaleFactor(0.8)
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
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 32
    
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
                        .minimumScaleFactor(0.8)
                    
                    Text(description)
                        .font(.petlyBody(13))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.leading)
                        .minimumScaleFactor(0.8)
                }
                
                Spacer()
                
                Image(systemName: icon)
                    .font(.system(size: iconSize))
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
