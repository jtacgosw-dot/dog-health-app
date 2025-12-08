import SwiftUI

struct DailyLogEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    let logItems = [
        LogItem(icon: "🍖", title: "Meals"),
        LogItem(icon: "🚶", title: "Walk"),
        LogItem(icon: "🦴", title: "Treat"),
        LogItem(icon: "🩺", title: "Symptom"),
        LogItem(icon: "💧", title: "Water"),
        LogItem(icon: "🎾", title: "Playtime"),
        LogItem(icon: "💩", title: "Digestion"),
        LogItem(icon: "✂️", title: "Grooming"),
        LogItem(icon: "😊", title: "Mood"),
        LogItem(icon: "💊", title: "Supplements"),
        LogItem(icon: "📅", title: "Upcoming Appointments"),
        LogItem(icon: "📝", title: "Notes")
    ]
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Daily Log Entry")
                        .font(.petlyTitle(28))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Spacer()
                    
                    if let dog = appState.currentDog {
                        Circle()
                            .fill(Color.petlyLightGreen)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("🐕")
                                    .font(.system(size: 25))
                            )
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(logItems) { item in
                            LogItemRow(item: item)
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

struct LogItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
}

struct LogItemRow: View {
    let item: LogItem
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
    DailyLogEntryView()
        .environmentObject(AppState())
}
