import SwiftUI

struct ItemListView: View {
    @StateObject private var viewModel = ItemViewModel(repository: FirebaseItemRepository())
    @StateObject private var profileService = ProfileService.shared
    @State private var isShowingAddItem = false
    @State private var selectedItem: Item?

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.sortedItems) { item in
                    Button {
                        selectedItem = item
                    } label: {
                        ItemRowView(item: item)
                    }
                    .buttonStyle(.plain)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete(perform: viewModel.deleteItems)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle(profileService.profile?.martName ?? "Inventory")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.sortedItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary)

                        Text("No Items")
                            .font(.headline)

                        Text("Tap + to add your first inventory item.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding()
                }
            }
            .alert("Inventory Error", isPresented: errorAlertBinding) {
                Button("OK") {
                    viewModel.clearErrorMessage()
                }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        ProfileView()
                    } label: {
                        ProfileAvatarView(
                            imageUrl: profileService.profile?.profileImageUrl,
                            title: profileService.profile?.martName,
                            size: 34
                        )
                    }
                    .accessibilityLabel("Profile")
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isShowingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add item")
                    .disabled(viewModel.isLoading)
                }
            }
            .sheet(isPresented: $isShowingAddItem) {
                AddEditItemView(viewModel: viewModel)
            }
            .sheet(item: $selectedItem) { item in
                AddEditItemView(viewModel: viewModel, item: item)
            }
            .task {
                profileService.startListening()
            }
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.clearErrorMessage()
                }
            }
        )
    }
}

private struct ItemRowView: View {
    let item: Item

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(item.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text(item.stockStatus.title)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(item.stockStatus.badgeBackgroundColor)
                    .foregroundStyle(item.stockStatus.badgeForegroundColor)
                    .clipShape(Capsule())
            }

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .foregroundStyle(.secondary)
                    Text("Qty: \(item.quantity)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                    Text("Threshold: \(item.threshold)")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }
}


private extension ItemStockStatus {
    var title: String {
        switch self {
        case .normal:
            return "In Stock"
        case .lowStock:
            return "Low Stock"
        }
    }

    var badgeBackgroundColor: Color {
        switch self {
        case .normal:
            return .green.opacity(0.14)
        case .lowStock:
            return .red.opacity(0.14)
        }
    }

    var badgeForegroundColor: Color {
        switch self {
        case .normal:
            return .green
        case .lowStock:
            return .red
        }
    }
}

struct ItemListView_Previews: PreviewProvider {
    static var previews: some View {
        ItemListView()
    }
}
