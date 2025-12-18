import SwiftUI

struct DailyLogEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    
    let logItems = [
        LogItem(icon: "fork.knife", title: "Meals"),
        LogItem(icon: "figure.walk", title: "Walk"),
        LogItem(icon: "gift.fill", title: "Treat"),
        LogItem(icon: "stethoscope", title: "Symptom"),
        LogItem(icon: "drop.fill", title: "Water"),
        LogItem(icon: "sportscourt.fill", title: "Playtime"),
        LogItem(icon: "leaf.arrow.triangle.circlepath", title: "Digestion"),
        LogItem(icon: "scissors", title: "Grooming"),
        LogItem(icon: "face.smiling.fill", title: "Mood"),
        LogItem(icon: "pills.fill", title: "Supplements"),
        LogItem(icon: "calendar", title: "Upcoming Appointments"),
        LogItem(icon: "note.text", title: "Notes")
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
                                Image(systemName: "dog.fill")
                                    .font(.system(size: 25))
                                    .foregroundColor(.petlyDarkGreen)
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
    DailyLogEntryView()
        .environmentObject(AppState())
}
