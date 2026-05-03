import Combine
import FirebaseAuth

class AuthService: ObservableObject {

    static let shared = AuthService()

    @Published var user: User?

    private var authStateHandle: AuthStateDidChangeListenerHandle?

    private init() {
        user = Auth.auth().currentUser

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }

    func signUp(email: String, password: String, martName: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        try await ProfileService.shared.createProfile(
            uid: result.user.uid,
            email: email,
            martName: martName
        )
    }

    func login(email: String, password: String) async throws {
        try await Auth.auth().signIn(withEmail: email, password: password)
    }

    func logout() throws {
        ProfileService.shared.clear()
        try Auth.auth().signOut()
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    deinit {
        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
        }
    }
}
