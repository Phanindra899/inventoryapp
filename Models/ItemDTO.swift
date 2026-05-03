import Foundation

struct ItemDTO: Codable {
    var id: String
    var name: String
    var quantity: Int
    var threshold: Int
}

extension ItemDTO {
    init(item: Item) {
        id = item.id.uuidString
        name = item.name
        quantity = item.quantity
        threshold = item.threshold
    }

    func toItem() throws -> Item {
        guard let uuid = UUID(uuidString: id) else {
            throw ItemDTOError.invalidID
        }

        return Item(
            id: uuid,
            name: name,
            quantity: quantity,
            threshold: threshold
        )
    }
}

extension Item {
    func toDTO() -> ItemDTO {
        ItemDTO(item: self)
    }
}

enum ItemDTOError: LocalizedError {
    case invalidID

    var errorDescription: String? {
        switch self {
        case .invalidID:
            return "The item identifier is invalid."
        }
    }
}
