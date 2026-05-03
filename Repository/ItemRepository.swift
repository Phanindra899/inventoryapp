import Foundation

protocol ItemRepository {
    func fetchItems() async throws -> [Item]
    func listenItems(_ onChange: @escaping (Result<[Item], Error>) -> Void) -> (() -> Void)
    func addItem(_ item: Item) async throws
    func updateItem(_ item: Item) async throws
    func deleteItem(_ item: Item) async throws
}

enum ItemRepositoryError: LocalizedError {
    case itemNotFound

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "The selected item could not be found."
        }
    }
}
