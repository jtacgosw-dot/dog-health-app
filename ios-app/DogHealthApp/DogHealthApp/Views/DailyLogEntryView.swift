import SwiftUI

struct DailyLogEntryView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedLogType: LogType?
    @State private var petPhotoData: Data?
    
    @ScaledMetric(relativeTo: .body) private var avatarSize: CGFloat = 50
    private var cappedAvatarSize: CGFloat { min(avatarSize, 70) }
    
    let logItems: [(LogType, String, String)] = [
        (.meals, "fork.knife", "Meals"),
        (.walk, "figure.walk", "Walk"),
        (.treat, "gift.fill", "Treat"),
        (.symptom, "stethoscope", "Symptom"),
        (.water, "drop.fill", "Water"),
        (.playtime, "sportscourt.fill", "Playtime"),
        (.digestion, "leaf.arrow.triangle.circlepath", "Digestion"),
        (.grooming, "scissors", "Grooming"),
        (.mood, "face.smiling.fill", "Mood"),
        (.supplements, "pills.fill", "Supplements"),
        (.appointments, "calendar", "Upcoming Appointments"),
        (.notes, "note.text", "Notes")
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
                    
                    if appState.currentDog != nil {
                        if let photoData = petPhotoData,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: cappedAvatarSize, height: cappedAvatarSize)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: cappedAvatarSize, height: cappedAvatarSize)
                                .overlay(
                                    Image(systemName: "dog.fill")
                                        .font(.system(size: cappedAvatarSize * 0.5))
                                        .foregroundColor(.petlyDarkGreen)
                                )
                        }
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(logItems, id: \.0) { logType, icon, title in
                            LogItemRow(icon: icon, title: title) {
                                selectedLogType = logType
                            }
                        }
                    }
                    .background(Color.petlyLightGreen)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
        .fullScreenCover(item: $selectedLogType) { logType in
            LogDetailView(logType: logType)
                .environmentObject(appState)
                .buttonStyle(.plain)
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
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

struct LogItemRow: View {
    let icon: String
    let title: String
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
        .sensoryFeedback(.selection, trigger: isPressed)
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
