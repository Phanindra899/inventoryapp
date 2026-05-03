import SwiftUI
import FirebaseCore

@main
struct Assignment_iosApp: App {
    @StateObject private var authService: AuthService

    init() {
        FirebaseApp.configure()
        _authService = StateObject(wrappedValue: AuthService.shared)
        print("🔥 Firebase configured")
        print("Test from the assignment ios")
    }

    var body: some Scene {
        WindowGroup {
            if authService.user != nil {
                ItemListView()
            } else {
                LoginView()
            }
        }
    
    }
}
