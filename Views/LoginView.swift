import SwiftUI

struct LoginView: View {

    @State private var email = ""
    @State private var password = ""
    @State private var martName = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 20) {

            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)

            TextField("Mart Name", text: $martName)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.words)

            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            Button("Login") {
                login()
            }
            .disabled(isLoading)

            Button("Sign Up") {
                signUp()
            }
            .disabled(isLoading)

            Button("Forgot Password?") {
                resetPassword()
            }
            .disabled(isLoading)
        }
        .padding()
        .disabled(isLoading)
        .overlay {
            if isLoading {
                ProgressView()
            }
        }
    }

    func login() {
        guard validate(requiresMartName: false) else {
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            defer {
                isLoading = false
            }

            do {
                try await AuthService.shared.login(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signUp() {
        guard validate(requiresMartName: true) else {
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            defer {
                isLoading = false
            }

            do {
                try await AuthService.shared.signUp(
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                    password: password,
                    martName: martName
                )
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func resetPassword() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Enter your email first."
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            defer {
                isLoading = false
            }

            do {
                try await AuthService.shared.resetPassword(email: trimmedEmail)
                errorMessage = "Password reset email sent."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func validate(requiresMartName: Bool) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMartName = martName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Email is required."
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Password is required."
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return false
        }

        guard !requiresMartName || !trimmedMartName.isEmpty else {
            errorMessage = "Mart name is required."
            return false
        }

        errorMessage = nil
        return true
    }
}
