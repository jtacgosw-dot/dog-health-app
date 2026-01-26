import Foundation
import UIKit

class PetPhotoService {
    static let shared = PetPhotoService()
    
    private init() {}
    
    // MARK: - Photo Storage Key
    
    private func photoKey(for dogId: String) -> String {
        return "petPhoto_\(dogId)"
    }
    
    // MARK: - Load Photo
    
    func loadPhoto(for dogId: String) -> Data? {
        let key = photoKey(for: dogId)
        return UserDefaults.standard.data(forKey: key)
    }
    
    func loadImage(for dogId: String) -> UIImage? {
        guard let data = loadPhoto(for: dogId) else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Save Photo
    
    func savePhoto(_ data: Data, for dogId: String) {
        let key = photoKey(for: dogId)
        UserDefaults.standard.set(data, forKey: key)
        notifyPhotoChanged()
    }
    
    func saveImage(_ image: UIImage, for dogId: String, compressionQuality: CGFloat = 0.8) {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else { return }
        savePhoto(data, for: dogId)
    }
    
    // MARK: - Delete Photo
    
    func deletePhoto(for dogId: String) {
        let key = photoKey(for: dogId)
        UserDefaults.standard.removeObject(forKey: key)
        notifyPhotoChanged()
    }
    
    // MARK: - Notification
    
    private func notifyPhotoChanged() {
        NotificationCenter.default.post(name: .petPhotoDidChange, object: nil)
    }
}
