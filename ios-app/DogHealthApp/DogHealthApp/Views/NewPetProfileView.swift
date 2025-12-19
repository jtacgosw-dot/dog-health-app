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
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.petlyDarkGreen)
                            .padding(12)
                            .background(Color.petlyLightGreen)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.petlyDarkGreen)
                                .frame(width: 100, height: 100)
                            
                            if let profileImage = profileImage {
                                profileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "pawprint.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                            }
                            
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                Circle()
                                    .fill(Color.petlyLightGreen)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.petlyDarkGreen)
                                    )
                            }
                            .offset(x: 35, y: 35)
                        }
                        .onChange(of: selectedPhoto) { newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    profileImage = Image(uiImage: uiImage)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        Text("Tell us about your pet!")
                            .font(.petlyTitle(28))
                            .foregroundColor(.petlyDarkGreen)
                            .padding(.top, 10)
                        
                        VStack(spacing: 12) {
                            PetFormField(icon: "pawprint.fill", placeholder: "Your Pet's Name", text: $name)
                            PetFormField(icon: "clock", placeholder: "Your Pet's Age", text: $age, keyboardType: .numberPad)
                            PetFormField(icon: "hare", placeholder: "Breed", text: $breed)
                            PetFormField(icon: "scalemass", placeholder: "Weight", text: $weight, keyboardType: .decimalPad)
                            PetFormField(icon: "face.smiling", placeholder: "Personality", text: $personality)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "figure.stand.line.dotted.figure.stand")
                                    .foregroundColor(.petlyFormIcon)
                                    .frame(width: 24)
                                
                                Text("Gender")
                                    .font(.petlyBody(14))
                                    .foregroundColor(.petlyFormIcon)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.petlyFormIcon)
                            }
                            .padding()
                            .background(Color.petlyLightGreen)
                            .cornerRadius(12)
                            
                            PetFormField(icon: "allergens", placeholder: "Allergies", text: $allergies)
                            PetFormField(icon: "cross.case", placeholder: "Health Conditions", text: $healthConditions)
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
                            Text("COMPLETE")
                                .font(.petlyBodyMedium(16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.petlyDarkGreen)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 8) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(index == 3 ? Color.petlyDarkGreen : Color.petlyFormIcon.opacity(0.3))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
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

struct PetFormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.petlyFormIcon)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .font(.petlyBody(14))
                .keyboardType(keyboardType)
        }
        .padding()
        .background(Color.petlyLightGreen)
        .cornerRadius(12)
    }
}

#Preview {
    NewPetProfileView()
        .environmentObject(AppState())
}
