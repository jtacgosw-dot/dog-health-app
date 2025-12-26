import SwiftUI
import PhotosUI

struct PhotoAttachmentView: View {
    @Binding var photoData: Data?
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var showingActionSheet = false
    @State private var showingCamera = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo Attachment")
                .font(.petlyBodyMedium(14))
                .foregroundColor(.petlyDarkGreen)
            
            if let data = photoData, let uiImage = UIImage(data: data) {
                photoPreview(uiImage: uiImage)
            } else {
                addPhotoButton
            }
        }
    }
    
    private func photoPreview(uiImage: UIImage) -> some View {
        VStack(spacing: 12) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .clipped()
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.petlySageGreen.opacity(0.3), lineWidth: 1)
                )
            
            HStack(spacing: 16) {
                Button(action: { showingActionSheet = true }) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                        Text("Replace")
                    }
                    .font(.petlyBody(14))
                    .foregroundColor(.petlyDarkGreen)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.petlyLightGreen)
                    .cornerRadius(20)
                }
                
                Button(action: { photoData = nil }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove")
                    }
                    .font(.petlyBody(14))
                    .foregroundColor(.red)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(20)
                }
            }
        }
        .confirmationDialog("Change Photo", isPresented: $showingActionSheet) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        photoData = data
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(photoData: $photoData)
        }
    }
    
    private var addPhotoButton: some View {
        Button(action: { showingActionSheet = true }) {
            VStack(spacing: 12) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.petlyFormIcon)
                
                Text("Add Photo")
                    .font(.petlyBodyMedium(14))
                    .foregroundColor(.petlyDarkGreen)
                
                Text("Tap to take or choose a photo")
                    .font(.petlyBody(12))
                    .foregroundColor(.petlyFormIcon)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .background(Color.petlyLightGreen)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.petlySageGreen.opacity(0.3), lineWidth: 1)
            )
        }
        .confirmationDialog("Add Photo", isPresented: $showingActionSheet) {
            Button("Take Photo") {
                showingCamera = true
            }
            Button("Choose from Library") {
                showingImagePicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
        .onChange(of: selectedItem) { oldValue, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        photoData = data
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(photoData: $photoData)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var photoData: Data?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.photoData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct PhotoThumbnailView: View {
    let photoData: Data?
    var size: CGFloat = 60
    
    var body: some View {
        if let data = photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipped()
                .cornerRadius(8)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.petlyLightGreen)
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundColor(.petlyFormIcon)
                )
        }
    }
}

#Preview {
    VStack {
        PhotoAttachmentView(photoData: .constant(nil))
            .padding()
    }
}
