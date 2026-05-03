import Foundation

enum ItemStockStatus: Equatable {
    case normal
    case lowStock
}

struct Item: Identifiable, Equatable {
    let id: UUID
    var name: String
    var quantity: Int
    var threshold: Int

    var stockStatus: ItemStockStatus {
        quantity < threshold ? .lowStock : .normal
    }

    init(
        id: UUID = UUID(),
        name: String,
        quantity: Int,
        threshold: Int
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.threshold = threshold
    }
}
