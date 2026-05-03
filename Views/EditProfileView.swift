import PhotosUI
import SwiftUI

struct EditProfileView: View {
    let profile: UserProfile?

    @Environment(\.dismiss) private var dismiss
    @State private var martName: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var errorMessage: String?
    @State private var isSaving = false

    init(profile: UserProfile?) {
        self.profile = profile
        _martName = State(initialValue: profile?.martName ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 16) {
                        avatar
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Text("Change Photo")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                        .disabled(isSaving)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .listRowBackground(Color.clear)
                }

                Section("Mart Details") {
                    TextField("Mart Name", text: $martName)
                        .textInputAutocapitalization(.words)
                        .disabled(isSaving)
                        .padding(.vertical, 4)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(isSaving)
                }
            }
            .overlay {
                if isSaving {
                    ZStack {
                        Color.black.opacity(0.15).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.primary)
                            Text("Saving...")
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(24)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                loadImage(from: newValue)
            }
        }
    }

    private var avatar: some View {
        ZStack {
            if let selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ProfileAvatarView(
                    imageUrl: profile?.profileImageUrl,
                    title: martName,
                    size: 104
                )
            }
        }
        .frame(width: 104, height: 104)
        .clipShape(Circle())
    }

    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else {
            return
        }

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    errorMessage = "The selected image could not be loaded."
                    return
                }

                selectedImage = image
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil

        Task {
            defer {
                isSaving = false
            }

            do {
                try await ProfileService.shared.updateProfile(
                    martName: martName,
                    image: selectedImage
                )
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
