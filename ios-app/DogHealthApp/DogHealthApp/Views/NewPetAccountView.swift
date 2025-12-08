import SwiftUI

struct NewPetAccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    let menuItems = [
        MenuItem(icon: "👥", title: "Invite Friends"),
        MenuItem(icon: "🎧", title: "Customer Support"),
        MenuItem(icon: "🍖", title: "Nutrition"),
        MenuItem(icon: "🐾", title: "Personality"),
        MenuItem(icon: "💚", title: "Health Concerns"),
        MenuItem(icon: "⚖️", title: "Weight"),
        MenuItem(icon: "⚙️", title: "General"),
        MenuItem(icon: "💎", title: "Membership")
    ]
    
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
                
                Text("Pet Account")
                    .font(.petlyTitle(28))
                    .foregroundColor(.petlyDarkGreen)
                    .padding(.bottom, 20)
                
                Circle()
                    .fill(Color.petlyLightGreen)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text("🐕")
                            .font(.system(size: 60))
                    )
                    .overlay(
                        Circle()
                            .fill(Color.petlyDarkGreen)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 40, y: 40)
                    )
                    .padding(.bottom, 16)
                
                Text("\(appState.currentDog?.name ?? "Arlo"), \(appState.currentDog?.age ?? 1) Year")
                    .font(.petlyTitle(24))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("Breed: \(appState.currentDog?.breed ?? "Mini Poodle")")
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyFormIcon)
                    .padding(.bottom, 30)
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(menuItems) { item in
                            MenuItemRow(item: item)
                        }
                    }
                    .background(Color.petlyLightGreen)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
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
                Text(item.icon)
                    .font(.system(size: 24))
                
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
