import SwiftUI
import PhotosUI

struct PetProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var breed = ""
    @State private var age = ""
    @State private var weight = ""
    @State private var healthConcerns = ""
    @State private var allergies = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profileImage: Image?
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.petlyCream
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            ZStack {
                                if let profileImage = profileImage {
                                    profileImage
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(Color.petlyDarkGreen, lineWidth: 3)
                                        )
                                        .transition(.scale.combined(with: .opacity))
                                } else {
                                    Circle()
                                        .fill(Color.petlySageGreen.opacity(0.3))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            VStack(spacing: 8) {
                                                Image(systemName: "camera.fill")
                                                    .font(.system(size: 30))
                                                    .foregroundColor(.petlyDarkGreen)
                                                Text("Add Photo")
                                                    .font(.caption)
                                                    .foregroundColor(.petlyDarkGreen)
                                            }
                                        )
                                }
                            }
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: profileImage != nil)
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 20) {
                            ProfileTextField(title: "Name", text: $name, icon: "pawprint.fill")
                            ProfileTextField(title: "Breed", text: $breed, icon: "tag.fill")
                            ProfileTextField(title: "Age (years)", text: $age, icon: "calendar", keyboardType: .numberPad)
                            ProfileTextField(title: "Weight (lbs)", text: $weight, icon: "scalemass", keyboardType: .decimalPad)
                            ProfileTextField(title: "Health Concerns", text: $healthConcerns, icon: "heart.text.square", multiline: true)
                            ProfileTextField(title: "Allergies", text: $allergies, icon: "exclamationmark.triangle", multiline: true)
                        }
                        .padding(.horizontal)
                        
                        if let errorMessage = errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        if showSuccess {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Profile saved successfully!")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .padding(.horizontal)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        Button(action: saveProfile) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Save Profile")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.petlyDarkGreen)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                            .shadow(color: Color.petlyDarkGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading || name.isEmpty)
                        .opacity(name.isEmpty ? 0.6 : 1.0)
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                        .scaleEffect(isLoading ? 0.95 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLoading)
                    }
                }
            }
            .navigationTitle("Pet Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        Image(systemName: "pawprint.fill")
                            .foregroundColor(.petlyDarkGreen)
                        Text("Pet Profile")
                            .font(.headline)
                            .foregroundColor(.petlyDarkGreen)
                    }
                }
            }
        }
        .onAppear {
            loadCurrentDog()
        }
        .onChange(of: selectedPhoto) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        withAnimation {
                            profileImage = Image(uiImage: uiImage)
                        }
                    }
                }
            }
        }
    }
    
    private func loadCurrentDog() {
        guard let dog = appState.currentDog else { return }
        name = dog.name
        breed = dog.breed
        age = String(dog.age)
        if let dogWeight = dog.weight {
            weight = String(format: "%.1f", dogWeight)
        }
        healthConcerns = dog.healthConcerns.joined(separator: ", ")
        allergies = dog.allergies.joined(separator: ", ")
    }
    
    private func saveProfile() {
        guard !name.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        showSuccess = false
        
        Task {
            do {
                let ageInt = Int(age) ?? 0
                let weightDouble = Double(weight)
                let healthConcernsArray = healthConcerns.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                let allergiesArray = allergies.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                
                let dog: Dog
                if let existingDog = appState.currentDog {
                    dog = try await APIService.shared.updateDog(
                        dogId: existingDog.id,
                        name: name,
                        breed: breed,
                        age: ageInt,
                        weight: weightDouble,
                        healthConcerns: healthConcernsArray,
                        allergies: allergiesArray
                    )
                } else {
                    dog = try await APIService.shared.createDog(
                        name: name,
                        breed: breed,
                        age: ageInt,
                        weight: weightDouble,
                        healthConcerns: healthConcernsArray,
                        allergies: allergiesArray
                    )
                }
                
                await MainActor.run {
                    appState.currentDog = dog
                    if let index = appState.dogs.firstIndex(where: { $0.id == dog.id }) {
                        appState.dogs[index] = dog
                    } else {
                        appState.dogs.append(dog)
                    }
                    isLoading = false
                    withAnimation {
                        showSuccess = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        errorMessage = "Failed to save profile: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct ProfileTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var multiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.petlyDarkGreen)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.petlyDarkGreen)
            }
            
            if multiline {
                TextEditor(text: $text)
                    .frame(height: 80)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.petlySageGreen.opacity(0.3), lineWidth: 1)
                    )
            } else {
                TextField("Enter \(title.lowercased())", text: $text)
                    .keyboardType(keyboardType)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.petlySageGreen.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
}

#Preview {
    PetProfileView()
        .environmentObject(AppState())
}
