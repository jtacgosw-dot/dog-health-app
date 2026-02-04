import SwiftUI

struct PetSwitcherView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showAddPet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        if appState.dogs.isEmpty {
                            emptyState
                        } else {
                            ForEach(appState.dogs, id: \.id) { dog in
                                PetCard(
                                    dog: dog,
                                    isSelected: appState.currentDog?.id == dog.id,
                                    onSelect: {
                                        appState.currentDog = dog
                                        dismiss()
                                    }
                                )
                            }
                        }
                        
                        addPetButton
                    }
                    .padding()
                }
            }
            .navigationTitle("My Pets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
            .sheet(isPresented: $showAddPet) {
                AddPetView()
                    .environmentObject(appState)
                    .buttonStyle(.plain)
            }
        }
        .buttonStyle(.plain)
        .preferredColorScheme(.light)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 60))
                .foregroundColor(.petlyFormIcon)
            
            Text("No pets added yet")
                .font(.petlyBodyMedium(18))
                .foregroundColor(.petlyDarkGreen)
            
            Text("Add your first pet to get started")
                .font(.petlyBody(14))
                .foregroundColor(.petlyFormIcon)
        }
        .padding(.vertical, 40)
    }
    
    private var addPetButton: some View {
        Button(action: { showAddPet = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("Add Another Pet")
                    .font(.petlyBodyMedium(16))
            }
            .foregroundColor(.petlyDarkGreen)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.petlyLightGreen)
            .cornerRadius(12)
        }
    }
}

struct PetCard: View {
    let dog: Dog
    let isSelected: Bool
    var onSelect: () -> Void
    @State private var isPressed = false
    @State private var checkmarkScale: CGFloat = 0
    @State private var petPhotoData: Data?
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            onSelect()
        }) {
            HStack(spacing: 16) {
                if let photoData = petPhotoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.petlyLightGreen)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "dog.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.petlyDarkGreen)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(dog.name)
                        .font(.petlyBodyMedium(18))
                        .foregroundColor(.petlyDarkGreen)
                    
                    if !dog.breed.isEmpty {
                        Text(dog.breed)
                            .font(.petlyBody(14))
                            .foregroundColor(.petlyFormIcon)
                    }
                    
                    Text("\(dog.ageDisplayString) old")
                        .font(.petlyBody(12))
                        .foregroundColor(.petlyFormIcon)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.petlyDarkGreen)
                        .scaleEffect(checkmarkScale)
                        .onAppear {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                checkmarkScale = 1.0
                            }
                        }
                }
            }
            .padding()
            .background(isSelected ? Color.petlyLightGreen : Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.petlyDarkGreen : Color.petlySageGreen.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            loadPetPhoto()
        }
    }
    
    private func loadPetPhoto() {
        // Load per-pet photo from Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let perPetPhotoURL = documentsDirectory.appendingPathComponent("petPhoto_\(dog.id).jpg")
        let legacyPhotoURL = documentsDirectory.appendingPathComponent("petPhoto.jpg")
        
        if FileManager.default.fileExists(atPath: perPetPhotoURL.path) {
            // Use per-pet photo if available
            petPhotoData = try? Data(contentsOf: perPetPhotoURL)
        } else if FileManager.default.fileExists(atPath: legacyPhotoURL.path) {
            // Fallback to legacy single photo for migration
            petPhotoData = try? Data(contentsOf: legacyPhotoURL)
        } else {
            // Fallback to legacy UserDefaults storage
            let key = "petPhoto_\(dog.id)"
            petPhotoData = UserDefaults.standard.data(forKey: key)
        }
    }
}

struct AddPetView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var breed = ""
    @State private var age = ""
    @State private var weight = ""
    @State private var gender = "Male"
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    let genders = ["Male", "Female"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "dog.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.petlyDarkGreen)
                                )
                            
                            Text("Add a New Pet")
                                .font(.petlyTitle(24))
                                .foregroundColor(.petlyDarkGreen)
                        }
                        .padding(.top)
                        
                        VStack(spacing: 16) {
                            AddPetFormField(title: "Name", placeholder: "Pet's name", text: $name)
                            AddPetFormField(title: "Breed", placeholder: "e.g., Golden Retriever", text: $breed)
                            AddPetFormField(title: "Age", placeholder: "Age in years", text: $age, keyboardType: .numberPad)
                            AddPetFormField(title: "Weight", placeholder: "Weight in lbs", text: $weight, keyboardType: .decimalPad)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.petlyBodyMedium(14))
                                    .foregroundColor(.petlyDarkGreen)
                                
                                HStack(spacing: 12) {
                                    ForEach(genders, id: \.self) { g in
                                        Button(action: { gender = g }) {
                                            Text(g)
                                                .font(.petlyBody(14))
                                                .foregroundColor(gender == g ? .white : .petlyDarkGreen)
                                                .padding(.horizontal, 24)
                                                .padding(.vertical, 12)
                                                .background(gender == g ? Color.petlyDarkGreen : Color.petlyLightGreen)
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(16)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.petlyBody(14))
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        Button(action: addPet) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.petlyDarkGreen)
                                    .cornerRadius(12)
                            } else {
                                Text("Add Pet")
                                    .font(.petlyBodyMedium(16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(name.isEmpty ? Color.gray : Color.petlyDarkGreen)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(name.isEmpty || isLoading)
                        .padding(.top)
                    }
                    .padding()
                }
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
        .preferredColorScheme(.light)
    }
    
    private func addPet() {
        errorMessage = nil
        
        let ageDouble = Double(age) ?? 0
        let weightDouble = Double(weight)
        
        if ageDouble < 0 {
            errorMessage = "Age cannot be negative"
            return
        }
        
        if let w = weightDouble, w < 0 {
            errorMessage = "Weight cannot be negative"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let newDog = Dog(
                    name: name,
                    breed: breed.isEmpty ? "Unknown" : breed,
                    age: ageDouble,
                    weight: weightDouble
                )
                
                let createdDog = try await APIService.shared.createDog(dog: newDog)
                
                await MainActor.run {
                    // Save dog locally so it persists across app restarts
                    // This ensures pet photos can be loaded with the correct dog ID
                    appState.saveDogLocally(createdDog)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to add pet: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
}

struct AddPetFormField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            TextField(placeholder, text: $text)
                .font(.petlyBody(16))
                .padding()
                .background(Color.petlyLightGreen)
                .cornerRadius(12)
                .keyboardType(keyboardType)
        }
    }
}

struct PetSwitcherButton: View {
    @EnvironmentObject var appState: AppState
    @Binding var showPetSwitcher: Bool
    
    var body: some View {
        Button(action: { showPetSwitcher = true }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.petlyLightGreen)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "dog.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.petlyDarkGreen)
                    )
                
                if let dog = appState.currentDog {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(dog.name)
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                        
                        if appState.dogs.count > 1 {
                            Text("Tap to switch")
                                .font(.petlyBody(10))
                                .foregroundColor(.petlyFormIcon)
                        }
                    }
                }
                
                if appState.dogs.count > 1 {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.petlyFormIcon)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
}

#Preview {
    PetSwitcherView()
        .environmentObject(AppState())
}
