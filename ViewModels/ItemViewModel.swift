import Foundation
import Combine

enum ItemValidationError: LocalizedError {
    case emptyName
    case invalidQuantity
    case invalidThreshold

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Item name is required."
        case .invalidQuantity:
            return "Quantity must be a valid whole number."
        case .invalidThreshold:
            return "Threshold must be a valid whole number."
        }
    }
}

@MainActor
final class ItemViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var validationMessage: String?

    private let repository: any ItemRepository
    private var stopListening: (() -> Void)?
    private var hasReceivedInitialSnapshot = false

    var sortedItems: [Item] {
        items.sorted { firstItem, secondItem in
            if firstItem.stockStatus != secondItem.stockStatus {
                return firstItem.stockStatus == .lowStock
            }

            return firstItem.name.localizedCaseInsensitiveCompare(secondItem.name) == .orderedAscending
        }
    }

    init(repository: any ItemRepository = FirebaseItemRepository()){
        self.repository = repository
        startListeningToItems()
    }

    deinit {
        stopListening?()
    }

    func loadItems() {
        startListeningToItems()
    }

    func startListeningToItems() {
        guard stopListening == nil else {
            return
        }

        isLoading = true
        errorMessage = nil

        stopListening = repository.listenItems { [weak self] result in
            DispatchQueue.main.async {
                self?.handleItemsSnapshot(result)
            }
        }
    }

    func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.compactMap { index in
            sortedItems.indices.contains(index) ? sortedItems[index] : nil
        }

        guard !itemsToDelete.isEmpty else {
            return
        }

        guard beginOperation() else {
            return
        }

        Task {
            await completeStartedOperation {
                for item in itemsToDelete {
                    try await repository.deleteItem(item)
                }

                let deletedIDs = Set(itemsToDelete.map(\.id))
                items.removeAll { deletedIDs.contains($0.id) }
            }
        }
    }

    @discardableResult
    func saveItem(
        existingItem: Item?,
        name: String,
        quantityText: String,
        thresholdText: String
    ) async -> Bool {
        guard beginOperation() else {
            return false
        }

        let validatedItem: Item

        do {
            validatedItem = try makeValidatedItem(
                existingItem: existingItem,
                name: name,
                quantityText: quantityText,
                thresholdText: thresholdText
            )
        } catch {
            validationMessage = error.localizedDescription
            isLoading = false
            return false
        }

        validationMessage = nil

        return await completeStartedOperation {
            if existingItem == nil {
                try await repository.addItem(validatedItem)
                upsertLocalItem(validatedItem)
            } else {
                try await repository.updateItem(validatedItem)
                upsertLocalItem(validatedItem)
            }
        }
    }

    func clearValidationMessage() {
        validationMessage = nil
    }

    func clearErrorMessage() {
        errorMessage = nil
    }

    private func makeValidatedItem(
        existingItem: Item?,
        name: String,
        quantityText: String,
        thresholdText: String
    ) throws -> Item {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            throw ItemValidationError.emptyName
        }

        guard let quantity = Int(quantityText), quantity >= 0 else {
            throw ItemValidationError.invalidQuantity
        }

        guard let threshold = Int(thresholdText), threshold >= 0 else {
            throw ItemValidationError.invalidThreshold
        }

        return Item(
            id: existingItem?.id ?? UUID(),
            name: trimmedName,
            quantity: quantity,
            threshold: threshold
        )
    }

    @discardableResult
    private func beginOperation() -> Bool {
        guard !isLoading else {
            return false
        }

        isLoading = true
        errorMessage = nil
        return true
    }

    private func handleItemsSnapshot(_ result: Result<[Item], Error>) {
        switch result {
        case .success(let items):
            self.items = items
        case .failure(let error):
            errorMessage = error.localizedDescription
        }

        if !hasReceivedInitialSnapshot {
            hasReceivedInitialSnapshot = true
            isLoading = false
        }
    }

    private func updateLocalItem(_ item: Item) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }

        items[index] = item
    }

    private func upsertLocalItem(_ item: Item) {
        guard items.contains(where: { $0.id == item.id }) else {
            items.append(item)
            return
        }

        updateLocalItem(item)
    }

    @discardableResult
    private func completeStartedOperation(_ operation: () async throws -> Void) async -> Bool {
        defer {
            isLoading = false
        }

        do {
            try await operation()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
