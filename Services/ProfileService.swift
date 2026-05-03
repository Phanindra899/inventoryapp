import Combine
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import UIKit

final class ProfileService: ObservableObject {
    
    static let shared = ProfileService()
    
    @Published private(set) var profile: UserProfile?
    @Published private(set) var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private var listener: ListenerRegistration?
    private var currentUID: String?
    
    private init() {}
    
    // MARK: - CREATE PROFILE
    
    func createProfile(uid: String, email: String, martName: String) async throws {
        let cleanName = martName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let data: [String: Any] = [
            "email": email,
            "martName": cleanName,
            "profileImageUrl": "",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        try await db.collection("users").document(uid).setData(data, merge: true)
    }
    
    // MARK: - LISTEN PROFILE
    
    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                self.profile = nil
                self.errorMessage = "User not logged in"
            }
            return
        }
        
        if currentUID == uid { return }
        
        stopListening()
        currentUID = uid
        
        listener = db.collection("users").document(uid)
            .addSnapshotListener { [weak self] snapshot, error in
                
                guard let self else { return }
                
                DispatchQueue.main.async {
                    if let error {
                        self.errorMessage = error.localizedDescription
                        return
                    }
                    
                    let data = snapshot?.data() ?? [:]
                    
                    let email = data["email"] as? String ?? ""
                    let martName = data["martName"] as? String ?? "My Mart"
                    let imageUrl = data["profileImageUrl"] as? String
                    
                    self.profile = UserProfile(
                        email: email,
                        martName: martName,
                        profileImageUrl: imageUrl?.isEmpty == true ? nil : imageUrl
                    )
                    
                    self.errorMessage = nil
                }
            }
    }
    
    // MARK: - UPDATE PROFILE
    
    func updateProfile(martName: String, image: UIImage?) async throws {
        
        guard let uid = Auth.auth().currentUser?.uid else {
            throw ProfileError.userNotFound
        }
        
        let cleanName = martName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanName.isEmpty {
            throw ProfileError.emptyMartName
        }
        
        var updateData: [String: Any] = [
            "martName": cleanName
        ]
        
        if let image {
            let url = try await uploadImage(image, uid: uid)
            updateData["profileImageUrl"] = url
        }
        
        try await db.collection("users").document(uid).setData(updateData, merge: true)
    }
    
    // MARK: - CLEAR
    
    func clear() {
        stopListening()
        DispatchQueue.main.async {
            self.profile = nil
            self.errorMessage = nil
        }
    }
    
    private func stopListening() {
        listener?.remove()
        listener = nil
        currentUID = nil
    }
    
    // MARK: - IMAGE UPLOAD (FIXED)
    
    private func uploadImage(_ image: UIImage, uid: String) async throws -> String {
        
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw ProfileError.invalidImage
        }
        
        let ref = storage.reference().child("profileImages/\(uid).jpg")
        
        do {
            // Upload
            _ = try await ref.putDataAsync(data)
            
            // Confirm upload
            _ = try await ref.getMetadata()
            
            // Get URL
            let url = try await ref.downloadURL()
            
            print("✅ Upload success:", url.absoluteString)
            
            return url.absoluteString
            
        } catch {
            print("❌ Upload failed:", error.localizedDescription)
            throw error
        }
    }
}

// MARK: - ERROR ENUM

enum ProfileError: LocalizedError {
    case userNotFound
    case emptyMartName
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not logged in"
        case .emptyMartName:
            return "Mart name required"
        case .invalidImage:
            return "Invalid image selected"
        }
    }
}
