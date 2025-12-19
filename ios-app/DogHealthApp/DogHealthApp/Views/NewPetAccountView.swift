import SwiftUI

struct NewPetAccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var scrollOffset: CGFloat = 0
    
    let topMenuItems = [
        MenuItem(icon: "person.2.fill", title: "Invite Friends"),
        MenuItem(icon: "headphones", title: "Customer Support")
    ]
    
    let mainMenuItems = [
        MenuItem(icon: "fork.knife", title: "Nutrition"),
        MenuItem(icon: "pawprint.fill", title: "Personality"),
        MenuItem(icon: "heart.fill", title: "Health Concerns"),
        MenuItem(icon: "scalemass", title: "Weight"),
        MenuItem(icon: "gearshape.fill", title: "General"),
        MenuItem(icon: "sparkles", title: "Membership")
    ]
    
    var headerScale: CGFloat {
        let minScale: CGFloat = 0.6
        let maxScale: CGFloat = 1.0
        let scale = max(minScale, maxScale - (scrollOffset / 300))
        return scale
    }
    
    var headerOpacity: Double {
        let minOpacity: Double = 0.3
        let maxOpacity: Double = 1.0
        let opacity = max(minOpacity, maxOpacity - Double(scrollOffset / 200))
        return opacity
    }
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
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
                }
                .padding()
                
                VStack(spacing: 12) {
                    Text("Pet Account")
                        .font(.petlyTitle(28))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: 120 * headerScale, height: 120 * headerScale)
                        .overlay(
                            Image(systemName: "dog.fill")
                                .font(.system(size: 60 * headerScale))
                                .foregroundColor(.petlyDarkGreen)
                        )
                        .overlay(
                            Circle()
                                .fill(Color.petlyDarkGreen)
                                .frame(width: 36 * headerScale, height: 36 * headerScale)
                                .overlay(
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14 * headerScale))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 40 * headerScale, y: 40 * headerScale)
                        )
                    
                    Text("\(appState.currentDog?.name ?? "Arlo"), \(appState.currentDog?.age ?? 1) Year")
                        .font(.petlyTitle(24 * headerScale))
                        .foregroundColor(.petlyDarkGreen)
                        .opacity(headerOpacity)
                    
                    Text("Breed: \(appState.currentDog?.breed ?? "Mini Poodle")")
                        .font(.petlyBody(14))
                        .foregroundColor(.petlyFormIcon)
                        .opacity(headerOpacity)
                }
                .padding(.bottom, 20)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scrollOffset)
                
                ScrollView {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 12) {
                        ForEach(topMenuItems) { item in
                            HStack(spacing: 16) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(.petlyDarkGreen)
                                    .frame(width: 24)
                                
                                Text(item.title)
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
                        
                        VStack(spacing: 0) {
                            ForEach(mainMenuItems) { item in
                                MenuItemRow(item: item)
                            }
                        }
                        .background(Color.petlyLightGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = max(0, -value)
                }
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct MenuItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}

struct MenuItemRow: View {
    let item: MenuItem
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
                Image(systemName: item.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.petlyDarkGreen)
                    .frame(width: 24)
                
                Text(item.title)
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
            Rectangle()
                .fill(Color.petlyDarkGreen.opacity(0.1))
                .frame(height: 1)
                .padding(.leading, 60),
            alignment: .bottom
        )
    }
}

#Preview {
    NewPetAccountView()
        .environmentObject(AppState())
}
