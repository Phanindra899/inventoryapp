import SwiftUI

struct ProfileView: View {
    @StateObject private var profileService = ProfileService.shared
    @State private var isShowingEditProfile = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    ProfileAvatarView(
                        imageUrl: profileService.profile?.profileImageUrl,
                        title: profileService.profile?.martName,
                        size: 112
                    )
                    .padding(.top, 16)

                    VStack(spacing: 6) {
                        Text(profileService.profile?.martName ?? "My Mart")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)

                        Text(profileService.profile?.email ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
                )

                VStack(spacing: 16) {
                    Button {
                        isShowingEditProfile = true
                    } label: {
                        Label("Edit Profile", systemImage: "pencil")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button(role: .destructive) {
                        logout()
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.secondarySystemBackground))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            profileService.startListening()
        }
        .sheet(isPresented: $isShowingEditProfile) {
            EditProfileView(profile: profileService.profile)
        }
        .alert("Profile Error", isPresented: errorAlertBinding) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "Something went wrong.")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private func logout() {
        do {
            try AuthService.shared.logout()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct ProfileAvatarView: View {
    let imageUrl: String?
    let title: String?
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallbackImage
                    @unknown default:
                        fallbackImage
                    }
                }
            } else {
                fallbackImage
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var fallbackImage: some View {
        Text(initials)
            .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
            .foregroundStyle(Color.accentColor)
    }

    private var initials: String {
        let source = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let words = source.split(separator: " ")
        let characters = words.prefix(2).compactMap(\.first)

        if characters.isEmpty {
            return "M"
        }

        return String(characters).uppercased()
    }
}
