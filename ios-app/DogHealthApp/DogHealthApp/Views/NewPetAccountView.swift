import SwiftUI
import UIKit

extension Notification.Name {
    static let petPhotoDidChange = Notification.Name("petPhotoDidChange")
}

// UIImagePickerController wrapper for reliable photo selection
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            // Try edited image first, then original
            if let image = info[.editedImage] as? UIImage {
                parent.onImagePicked(image)
            } else if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}


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
    @State private var showingEditProfile = false
    @State private var showingPhotoOptions = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    
        // Scaled sizes for Dynamic Type support
        @ScaledMetric(relativeTo: .body) private var profileAvatarSize: CGFloat = 120
    @ScaledMetric(relativeTo: .body) private var profileIconSize: CGFloat = 60
    @ScaledMetric(relativeTo: .body) private var editButtonSize: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var editIconSize: CGFloat = 14
    @ScaledMetric(relativeTo: .body) private var miniAvatarSize: CGFloat = 32
    @ScaledMetric(relativeTo: .body) private var miniIconSize: CGFloat = 16
    
    private var showMiniHeader: Bool {
        scrollOffset > 180
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        Color.clear.preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: -geometry.frame(in: .named("scroll")).minY
                        )
                    }
                    .frame(height: 0)
                    
                    VStack(spacing: 8) {
                        Text("Pet Account")
                            .font(.petlyTitle(28))
                            .foregroundColor(.petlyDarkGreen)
                        
                                                Button(action: { showingPhotoOptions = true }) {
                                                    ZStack {
                                                        if let photoData = appState.petPhotoData, let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: min(profileAvatarSize, 160), height: min(profileAvatarSize, 160))
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.petlyLightGreen)
                                        .frame(width: min(profileAvatarSize, 160), height: min(profileAvatarSize, 160))
                                        .overlay(
                                            Image(systemName: "dog.fill")
                                                .font(.system(size: min(profileIconSize, 80)))
                                                .foregroundColor(.petlyDarkGreen)
                                        )
                                }
                                
                                Circle()
                                    .fill(Color.petlyDarkGreen)
                                    .frame(width: min(editButtonSize, 48), height: min(editButtonSize, 48))
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: min(editIconSize, 18)))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: min(profileAvatarSize, 160) / 3, y: min(profileAvatarSize, 160) / 3)
                            }
                        }
                        .confirmationDialog("Change Pet Photo", isPresented: $showingPhotoOptions) {
                            Button("Take Photo") {
                                showingCamera = true
                            }
                            Button("Choose from Library") {
                                showingImagePicker = true
                            }
                            if appState.petPhotoData != nil {
                                Button("Remove Photo", role: .destructive) {
                                    appState.savePetPhoto(nil)
                                }
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(sourceType: .photoLibrary) { image in
                                // Compress and save the image
                                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                                    appState.savePetPhoto(jpegData)
                                }
                            }
                        }
                        .fullScreenCover(isPresented: $showingCamera) {
                            ImagePicker(sourceType: .camera) { image in
                                // Compress and save the image
                                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                                    appState.savePetPhoto(jpegData)
                                }
                            }
                        }
                        
                        Text("\(appState.currentDog?.name ?? "Arlo"), \(appState.currentDog?.ageDisplayString ?? "1 year") old")
                            .font(.petlyTitle(24))
                            .foregroundColor(.petlyDarkGreen)
                        
                        Text("Breed: \(appState.currentDog?.breed ?? "Mini Poodle")")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    }
                                        .padding(.top, 60)
                                        .padding(.bottom, 20)
                    
                    Button(action: { showingEditProfile = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.petlyDarkGreen)
                                .frame(width: 24)
                            
                            Text("Manage Profile")
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
                .padding(.bottom, 100)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .sheet(isPresented: $showingNutrition) {
                NutritionEditView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingPersonality) {
                PersonalityEditView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingHealthConcerns) {
                HealthConcernsEditView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingWeight) {
                WeightTrackingView()
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingGeneral) {
                SettingsView()
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingMembership) {
                MembershipStatusView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingInviteFriends) {
                InviteFriendsView()
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingCustomerSupport) {
                CustomerSupportView()
                    .buttonStyle(.plain)
            }
            .sheet(isPresented: $showingEditProfile) {
                EditPetProfileView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
            
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
                
                                if showMiniHeader {
                                    HStack(spacing: 8) {
                                        if let photoData = appState.petPhotoData, let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: min(miniAvatarSize, 44), height: min(miniAvatarSize, 44))
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: min(miniAvatarSize, 44), height: min(miniAvatarSize, 44))
                                .overlay(
                                    Image(systemName: "dog.fill")
                                        .font(.system(size: min(miniIconSize, 22)))
                                        .foregroundColor(.petlyDarkGreen)
                                )
                        }
                        
                        Text("\(appState.currentDog?.name ?? "Arlo")")
                            .font(.petlyTitle(18))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .background(
                Color.petlyBackground
                    .opacity(showMiniHeader ? 1 : 0)
                    .ignoresSafeArea(edges: .top)
            )
            .animation(.easeInOut(duration: 0.2), value: showMiniHeader)
        }
        .buttonStyle(.plain)
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

struct NutritionEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var feedingSchedule = "Twice daily"
    @State private var foodType = "Dry kibble"
    @State private var portionSize = "1 cup"
    @State private var allergies = ""
    @State private var showSaved = false
    
    let feedingOptions = ["Once daily", "Twice daily", "Three times daily", "Free feeding"]
    let foodTypes = ["Dry kibble", "Wet food", "Raw diet", "Home cooked", "Mixed"]
    let portionSizes = ["1/2 cup", "1 cup", "1.5 cups", "2 cups", "Custom"]
    
    private func loadExistingData() {
        if let dog = appState.currentDog {
            feedingSchedule = dog.feedingSchedule ?? "Twice daily"
            foodType = dog.foodType ?? "Dry kibble"
            portionSize = dog.portionSize ?? "1 cup"
            allergies = dog.foodAllergies ?? ""
        }
    }
    
    private func saveNutrition() {
        guard var dog = appState.currentDog else { return }
        dog.feedingSchedule = feedingSchedule
        dog.foodType = foodType
        dog.portionSize = portionSize
        dog.foodAllergies = allergies.isEmpty ? nil : allergies
        dog.updatedAt = Date()
        appState.saveDogLocally(dog)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feeding Schedule")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Picker("Feeding Schedule", selection: $feedingSchedule) {
                                ForEach(feedingOptions, id: \.self) { option in
                                    Text(option).tag(option)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Food Type")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Picker("Food Type", selection: $foodType) {
                                ForEach(foodTypes, id: \.self) { type in
                                    Text(type).tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Portion Size")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Picker("Portion Size", selection: $portionSize) {
                                ForEach(portionSizes, id: \.self) { size in
                                    Text(size).tag(size)
                                }
                            }
                            .pickerStyle(.menu)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Food Allergies / Sensitivities")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., chicken, grains", text: $allergies)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            saveNutrition()
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }) {
                            Text("Save Changes")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .onAppear {
                loadExistingData()
            }
            .overlay {
                if showSaved {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.petlyDarkGreen)
                        Text("Saved!")
                            .font(.petlyBodyMedium(18))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    .padding(40)
                    .background(Color.petlyLightGreen)
                    .cornerRadius(20)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

struct PersonalityEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var energyLevel = 3
    @State private var friendliness = 4
    @State private var trainability = 3
    @State private var selectedTraits: Set<String> = []
    @State private var showSaved = false
    
    let traits = ["Playful", "Calm", "Curious", "Protective", "Affectionate", "Independent", "Social", "Shy", "Energetic", "Lazy"]
    
    private func loadExistingData() {
        if let dog = appState.currentDog {
            energyLevel = dog.energyLevel ?? 3
            friendliness = dog.friendliness ?? 4
            trainability = dog.trainability ?? 3
            if let traits = dog.personalityTraits {
                selectedTraits = Set(traits)
            }
        }
    }
    
    private func savePersonality() {
        guard var dog = appState.currentDog else { return }
        dog.energyLevel = energyLevel
        dog.friendliness = friendliness
        dog.trainability = trainability
        dog.personalityTraits = Array(selectedTraits)
        dog.updatedAt = Date()
        appState.saveDogLocally(dog)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Energy Level")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            HStack {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: { energyLevel = level }) {
                                        Image(systemName: level <= energyLevel ? "bolt.fill" : "bolt")
                                            .font(.system(size: 24))
                                            .foregroundColor(level <= energyLevel ? .petlyDarkGreen : .petlyFormIcon)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Friendliness")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            HStack {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: { friendliness = level }) {
                                        Image(systemName: level <= friendliness ? "heart.fill" : "heart")
                                            .font(.system(size: 24))
                                            .foregroundColor(level <= friendliness ? .petlyDarkGreen : .petlyFormIcon)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trainability")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            HStack {
                                ForEach(1...5, id: \.self) { level in
                                    Button(action: { trainability = level }) {
                                        Image(systemName: level <= trainability ? "star.fill" : "star")
                                            .font(.system(size: 24))
                                            .foregroundColor(level <= trainability ? .petlyDarkGreen : .petlyFormIcon)
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personality Traits")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(traits, id: \.self) { trait in
                                    Button(action: {
                                        if selectedTraits.contains(trait) {
                                            selectedTraits.remove(trait)
                                        } else {
                                            selectedTraits.insert(trait)
                                        }
                                    }) {
                                        Text(trait)
                                            .font(.petlyBody(14))
                                            .foregroundColor(selectedTraits.contains(trait) ? .white : .petlyDarkGreen)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedTraits.contains(trait) ? Color.petlyDarkGreen : Color.petlyLightGreen)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        
                        Button(action: {
                            savePersonality()
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }) {
                            Text("Save Changes")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Personality")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .onAppear {
                loadExistingData()
            }
            .overlay {
                if showSaved {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.petlyDarkGreen)
                        Text("Saved!")
                            .font(.petlyBodyMedium(18))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    .padding(40)
                    .background(Color.petlyLightGreen)
                    .cornerRadius(20)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

struct HealthConcernsEditView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var selectedConditions: Set<String> = []
    @State private var otherConditions = ""
    @State private var medications = ""
    @State private var vetNotes = ""
    @State private var showSaved = false
    
    let commonConditions = ["Allergies", "Arthritis", "Diabetes", "Heart Disease", "Hip Dysplasia", "Obesity", "Dental Issues", "Skin Conditions", "Anxiety", "Digestive Issues"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Known Health Conditions")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(commonConditions, id: \.self) { condition in
                                    Button(action: {
                                        if selectedConditions.contains(condition) {
                                            selectedConditions.remove(condition)
                                        } else {
                                            selectedConditions.insert(condition)
                                        }
                                    }) {
                                        Text(condition)
                                            .font(.petlyBody(12))
                                            .foregroundColor(selectedConditions.contains(condition) ? .white : .petlyDarkGreen)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedConditions.contains(condition) ? Color.petlyDarkGreen : Color.petlyLightGreen)
                                            .cornerRadius(16)
                                    }
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Other Conditions")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("Enter any other conditions", text: $otherConditions)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Medications")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("List any medications", text: $medications)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Vet Notes")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextEditor(text: $vetNotes)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.petlyDarkGreen)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showSaved = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                dismiss()
                            }
                        }) {
                            Text("Save Changes")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Health Concerns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .overlay {
                if showSaved {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.petlyDarkGreen)
                        Text("Saved!")
                            .font(.petlyBodyMedium(18))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    .padding(40)
                    .background(Color.petlyLightGreen)
                    .cornerRadius(20)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

struct InviteFriendsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    
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
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.petlyDarkGreen)
                        )
                    
                    Text("Invite Friends")
                        .font(.petlyTitle(28))
                        .foregroundColor(.petlyDarkGreen)
                    
                    Text("Share Petly with friends and family to help them care for their pets too!")
                        .font(.petlyBody(16))
                        .foregroundColor(.petlyFormIcon)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    Button(action: { showShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Petly")
                        }
                        .font(.petlyBodyMedium(16))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.petlyDarkGreen)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    
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
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: ["Check out Petly - the best app for tracking your pet's health! Download it now."])
            }
        }
        .preferredColorScheme(.light)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CustomerSupportView: View {
    @Environment(\.dismiss) var dismiss
    @State private var subject = ""
    @State private var message = ""
    @State private var showSent = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Circle()
                            .fill(Color.petlyLightGreen)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "headphones")
                                    .font(.system(size: 36))
                                    .foregroundColor(.petlyDarkGreen)
                            )
                        
                        Text("How can we help?")
                            .font(.petlyTitle(24))
                            .foregroundColor(.petlyDarkGreen)
                        
                        Text("Our support team typically responds within 24 hours")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Subject")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("What's this about?", text: $subject)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextEditor(text: $message)
                                .scrollContentBackground(.hidden)
                                .foregroundColor(.petlyDarkGreen)
                                .frame(minHeight: 150)
                                .padding(8)
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            showSent = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }) {
                            Text("Send Message")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                        .disabled(subject.isEmpty || message.isEmpty)
                        .opacity(subject.isEmpty || message.isEmpty ? 0.6 : 1)
                        
                        HStack(spacing: 4) {
                            Text("Or email us at")
                                .font(.petlyBody(14))
                                .foregroundColor(.petlyFormIcon)
                            Text("support@petly.app")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Customer Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .overlay {
                if showSent {
                    VStack {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.petlyDarkGreen)
                        Text("Message Sent!")
                            .font(.petlyBodyMedium(18))
                            .foregroundColor(.petlyDarkGreen)
                        Text("We'll get back to you soon")
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    }
                    .padding(40)
                    .background(Color.petlyLightGreen)
                    .cornerRadius(20)
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

struct MembershipStatusView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var showPaywall = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if appState.hasActiveSubscription {
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.petlyLightGreen, Color.petlyDarkGreen.opacity(0.3)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.petlyDarkGreen)
                                }
                                
                                Text("Petly Premium")
                                    .font(.petlyTitle(28))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                Text("Active Subscription")
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(.petlyDarkGreen)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.petlyLightGreen)
                                    .cornerRadius(20)
                            }
                            .padding(.top, 40)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Your Benefits")
                                    .font(.petlyBodyMedium(18))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                BenefitRow(icon: "message.fill", title: "Unlimited AI Chat", description: "Get instant answers about pet health")
                                BenefitRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Insights", description: "AI-powered health pattern detection")
                                BenefitRow(icon: "doc.text.fill", title: "Vet Reports", description: "Export detailed health summaries")
                                BenefitRow(icon: "bell.fill", title: "Smart Reminders", description: "Never miss vaccinations or medications")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(16)
                            
                            Button(action: {
                                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Manage Subscription")
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(.petlyDarkGreen)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.petlyLightGreen)
                                    .cornerRadius(12)
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 60))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                Text("Free Plan")
                                    .font(.petlyTitle(28))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                Text("Upgrade to unlock all features")
                                    .font(.petlyBody(16))
                                    .foregroundColor(.petlyFormIcon)
                            }
                            .padding(.top, 40)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Upgrade to Premium")
                                    .font(.petlyBodyMedium(18))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                BenefitRow(icon: "message.fill", title: "Unlimited AI Chat", description: "Currently limited")
                                BenefitRow(icon: "chart.line.uptrend.xyaxis", title: "Advanced Insights", description: "Unlock AI analysis")
                                BenefitRow(icon: "doc.text.fill", title: "Vet Reports", description: "Export health summaries")
                                BenefitRow(icon: "bell.fill", title: "Smart Reminders", description: "Set unlimited reminders")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(16)
                            
                            Button(action: { showPaywall = true }) {
                                Text("Upgrade to Premium")
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.petlyDarkGreen)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Membership")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .sheet(isPresented: $showPaywall) {
                NewPaywallView()
                    .buttonStyle(.plain)
            }
        }
        .preferredColorScheme(.light)
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.petlyDarkGreen)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                Text(description)
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
        }
    }
}

struct EditPetProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var age = ""
    @State private var breed = ""
    @State private var weight = ""
    @State private var allergies = ""
    @State private var healthConditions = ""
    @State private var sex = ""
    @State private var isNeutered = false
    @State private var medicalHistory = ""
    @State private var currentMedications = ""
    @State private var showSaved = false
    @State private var errorMessage: String?
    @State private var showingPhotoOptions = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var originalDogId: String?
    @State private var originalCreatedAt: Date?
    
    var body: some View {
            NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                                                        Button(action: { showingPhotoOptions = true }) {
                                                            ZStack {
                                                                if let photoData = appState.petPhotoData, let uiImage = UIImage(data: photoData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(Circle())
                                    } else {
                                        Circle()
                                            .fill(Color.petlyLightGreen)
                                            .frame(width: 100, height: 100)
                                            .overlay(
                                                Image(systemName: "dog.fill")
                                                    .font(.system(size: 40))
                                                    .foregroundColor(.petlyDarkGreen)
                                            )
                                    }
                                    
                                    Circle()
                                        .fill(Color.petlyDarkGreen)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white)
                                        )
                                        .offset(x: 35, y: 35)
                                }
                            }
                            
                            Text("Tap to change photo")
                                .font(.petlyBody(12))
                                .foregroundColor(.petlyFormIcon)
                        }
                        .confirmationDialog("Change Pet Photo", isPresented: $showingPhotoOptions) {
                            Button("Take Photo") {
                                showingCamera = true
                            }
                            Button("Choose from Library") {
                                showingImagePicker = true
                            }
                            if appState.petPhotoData != nil {
                                Button("Remove Photo", role: .destructive) {
                                    appState.savePetPhoto(nil)
                                }
                            }
                            Button("Cancel", role: .cancel) { }
                        }
                        .sheet(isPresented: $showingImagePicker) {
                            ImagePicker(sourceType: .photoLibrary) { image in
                                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                                    appState.savePetPhoto(jpegData)
                                }
                            }
                        }
                        .fullScreenCover(isPresented: $showingCamera) {
                            ImagePicker(sourceType: .camera) { image in
                                if let jpegData = image.jpegData(compressionQuality: 0.8) {
                                    appState.savePetPhoto(jpegData)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pet Name")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("Name", text: $name)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age (years)")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("Age", text: $age)
                                .keyboardType(.numberPad)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Breed")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("Breed", text: $breed)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight (lbs)")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("Weight", text: $weight)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Allergies (comma separated)")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., chicken, grains", text: $allergies)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Health Conditions (comma separated)")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., arthritis, allergies", text: $healthConditions)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        // Sex picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sex")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            Picker("Sex", selection: $sex) {
                                Text("Not specified").tag("")
                                Text("Male").tag("Male")
                                Text("Female").tag("Female")
                            }
                            .pickerStyle(.segmented)
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        // Neutered/Spayed toggle
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $isNeutered) {
                                Text(sex == "Female" ? "Spayed" : "Neutered")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                            }
                            .tint(.petlyDarkGreen)
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                        }
                        
                        // Medical History
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Medical History")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., surgeries, past illnesses", text: $medicalHistory)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        // Current Medications
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Medications")
                                .font(.petlyBodyMedium(14))
                                .foregroundColor(.petlyDarkGreen)
                            
                            TextField("e.g., heartworm prevention, supplements", text: $currentMedications)
                                .padding()
                                .background(Color.petlyLightGreen)
                                .cornerRadius(12)
                        }
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.petlyBody(12))
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: saveProfile) {
                            Text("Save Changes")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                        .padding(.top, 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .overlay {
                if showSaved {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.petlyDarkGreen)
                        Text("Saved!")
                            .font(.petlyBodyMedium(18))
                            .foregroundColor(.petlyDarkGreen)
                    }
                    .padding(40)
                    .background(Color.petlyLightGreen)
                    .cornerRadius(20)
                }
            }
            .onAppear {
                if let dog = appState.currentDog {
                    originalDogId = dog.id
                    originalCreatedAt = dog.createdAt
                    name = dog.name
                    age = "\(dog.age)"
                    breed = dog.breed
                    if let w = dog.weight {
                        weight = String(format: "%.1f", w)
                    }
                    allergies = dog.allergies.joined(separator: ", ")
                    healthConditions = dog.healthConcerns.joined(separator: ", ")
                    sex = dog.sex ?? ""
                    isNeutered = dog.isNeutered ?? false
                    medicalHistory = dog.medicalHistory ?? ""
                    currentMedications = dog.currentMedications ?? ""
                    print("[EditPetProfileView] onAppear: Loaded dog \(dog.name) with id \(dog.id)")
                } else {
                                        print("[EditPetProfileView] onAppear: No currentDog found, using defaults")
                                        originalDogId = "00000000-0000-0000-0000-000000000001"
                    originalCreatedAt = Date()
                }
            }
            .preferredColorScheme(.light)
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty, !breed.isEmpty else {
            errorMessage = "Please fill in at least name and breed"
            return
        }
        
        guard let dogId = originalDogId, let createdAt = originalCreatedAt else {
            errorMessage = "No pet profile found"
            return
        }
        
        let ageDouble = Double(age) ?? 1.0
        let weightDouble = Double(weight)
        let allergiesArray = allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let healthConcernsArray = healthConditions.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        
        let updatedDog = Dog(
            id: dogId,
            name: name,
            breed: breed,
            age: ageDouble,
            weight: weightDouble,
            imageUrl: appState.currentDog?.imageUrl,
            healthConcerns: healthConcernsArray,
            allergies: allergiesArray,
            createdAt: createdAt,
            updatedAt: Date(),
            energyLevel: appState.currentDog?.energyLevel,
            friendliness: appState.currentDog?.friendliness,
            trainability: appState.currentDog?.trainability,
            personalityTraits: appState.currentDog?.personalityTraits,
            feedingSchedule: appState.currentDog?.feedingSchedule,
            foodType: appState.currentDog?.foodType,
            portionSize: appState.currentDog?.portionSize,
            foodAllergies: appState.currentDog?.foodAllergies,
            sex: sex.isEmpty ? nil : sex,
            isNeutered: isNeutered,
            medicalHistory: medicalHistory.isEmpty ? nil : medicalHistory,
            currentMedications: currentMedications.isEmpty ? nil : currentMedications
        )
        
        appState.saveDogLocally(updatedDog)
        print("[EditPetProfileView] Saved dog locally: \(updatedDog.name) with id \(dogId)")
        
        showSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            dismiss()
        }
        
        Task {
            do {
                _ = try await APIService.shared.updateDog(dog: updatedDog)
                print("[EditPetProfileView] API update succeeded")
            } catch {
                print("[EditPetProfileView] API update failed (local save still persists): \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    NewPetAccountView()
        .environmentObject(AppState())
}
