import Foundation

actor LocalItemRepository: ItemRepository {
    private var items: [Item]

    init(items: [Item] = []) {
        self.items = items
    }

    func fetchItems() async throws -> [Item] {
        items
    }

    nonisolated func listenItems(_ onChange: @escaping (Result<[Item], Error>) -> Void) -> (() -> Void) {
        Task {
            do {
                let items = try await fetchItems()
                onChange(.success(items))
            } catch {
                onChange(.failure(error))
            }
        }

        return {}
    }

    func addItem(_ item: Item) async throws {
        items.append(item)
    }

    func updateItem(_ item: Item) async throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw ItemRepositoryError.itemNotFound
        }

        items[index] = item
    }

    func deleteItem(_ item: Item) async throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw ItemRepositoryError.itemNotFound
        }

        items.remove(at: index)
    }
}
