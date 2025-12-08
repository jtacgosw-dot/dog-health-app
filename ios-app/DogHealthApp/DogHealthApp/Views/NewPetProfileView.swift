import SwiftUI
import PhotosUI

struct NewPetProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var age = ""
    @State private var breed = ""
    @State private var weight = ""
    @State private var personality = ""
    @State private var gender = "Male"
    @State private var allergies = ""
    @State private var healthConditions = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var showSuccessMessage = false
    @State private var errorMessage: String?
    
    let genders = ["Male", "Female"]
    
    var body: some View {
        ZStack {
            Color.petlyBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Tell us about your pet")
                        .font(.petlyTitle(28))
                        .foregroundColor(.petlyDarkGreen)
                        .padding(.top)
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack {
                            Circle()
                                .fill(Color.petlyLightGreen)
                                .frame(width: 120, height: 120)
                            
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(.petlyDarkGreen)
                                    Text("Add Photo")
                                        .font(.petlyBody(12))
                                        .foregroundColor(.petlyDarkGreen)
                                }
                            }
                        }
                    }
                    .onChange(of: selectedPhoto) { newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                profileImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        FormField(icon: "🐕", placeholder: "Name", text: $name)
                        FormField(icon: "🎂", placeholder: "Age", text: $age, keyboardType: .numberPad)
                        FormField(icon: "🦴", placeholder: "Breed", text: $breed)
                        FormField(icon: "⚖️", placeholder: "Weight (lbs)", text: $weight, keyboardType: .decimalPad)
                        FormField(icon: "😊", placeholder: "Personality", text: $personality)
                        
                        HStack(spacing: 12) {
                            Text("⚧️")
                                .font(.system(size: 20))
                            
                            Picker("Gender", selection: $gender) {
                                ForEach(genders, id: \.self) { gender in
                                    Text(gender)
                                        .font(.petlyBody())
                                        .tag(gender)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                        .background(Color.petlyLightGreen)
                        .cornerRadius(16)
                        
                        FormField(icon: "🚫", placeholder: "Allergies (comma separated)", text: $allergies)
                        FormField(icon: "🏥", placeholder: "Health Conditions (comma separated)", text: $healthConditions)
                    }
                    .padding(.horizontal)
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.petlyBody(12))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                    
                    if showSuccessMessage {
                        Text("Profile saved successfully! 🎉")
                            .font(.petlyBodyMedium(14))
                            .foregroundColor(.petlyDarkGreen)
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    Button(action: saveProfile) {
                        Text("Save Profile")
                            .font(.petlyBodyMedium(16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .cornerRadius(25)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty, !breed.isEmpty else {
            errorMessage = "Please fill in at least name and breed"
            return
        }
        
        Task {
            do {
                let ageInt = Int(age) ?? 0
                let weightDouble = Double(weight)
                let allergiesArray = allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let healthConcernsArray = healthConditions.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                
                let dog: Dog
                if let existingDog = appState.currentDog {
                    let updatedDog = Dog(
                        id: existingDog.id,
                        name: name,
                        breed: breed,
                        age: ageInt,
                        weight: weightDouble,
                        imageUrl: existingDog.imageUrl,
                        healthConcerns: healthConcernsArray,
                        allergies: allergiesArray,
                        createdAt: existingDog.createdAt,
                        updatedAt: Date()
                    )
                    dog = try await APIService.shared.updateDog(dog: updatedDog)
                } else {
                    let newDog = Dog(
                        name: name,
                        breed: breed,
                        age: ageInt,
                        weight: weightDouble,
                        healthConcerns: healthConcernsArray,
                        allergies: allergiesArray
                    )
                    dog = try await APIService.shared.createDog(dog: newDog)
                }
                
                await MainActor.run {
                    appState.currentDog = dog
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showSuccessMessage = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSuccessMessage = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save profile: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 20))
            
            TextField(placeholder, text: $text)
                .font(.petlyBody(14))
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(16)
    }
}

#Preview {
    NewPetProfileView()
        .environmentObject(AppState())
}
