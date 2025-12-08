import SwiftUI

struct NewMainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showDailyLog = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    HomeDashboardView()
                case 1:
                    NewChatView()
                case 2:
                    HomeDashboardView()
                case 3:
                    ExploreView()
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
                
                Text(title)
                    .font(.petlyBody(10))
                    .foregroundColor(isSelected ? .petlyLightGreen : .petlyFormIcon)
            }
            .frame(maxWidth: .infinity)
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

struct ExploreView: View {
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack {
                Text("Explore")
                    .font(.petlyTitle(32))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("Coming soon...")
                    .font(.petlyBody(16))
                    .foregroundColor(.petlyFormIcon)
            }
        }
    }
}

#Preview {
    NewMainTabView()
        .environmentObject(AppState())
}
