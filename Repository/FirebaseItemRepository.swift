import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseItemRepository: ItemRepository {

    private let db = Firestore.firestore()

    // MARK: - FETCH

    func fetchItems() async throws -> [Item] {

        let snapshot = try await itemsCollection().getDocuments()

        return snapshot.documents.map { doc in

            let data = doc.data()

            return Item(

                id: UUID(uuidString: doc.documentID) ?? UUID(),

                name: data["name"] as? String ?? "",

                quantity: data["quantity"] as? Int ?? 0,

                threshold: data["threshold"] as? Int ?? 0

            )

        }

    }
    func deleteItem(id: String) async throws {
    guard let uid = Auth.auth().currentUser?.uid else {
        throw NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])
    }

    try await db.collection("users")
        .document(uid)
        .collection("items")
        .document(id)
        .delete()
}

    // MARK: - LISTEN

    func listenItems(_ onChange: @escaping (Result<[Item], Error>) -> Void) -> (() -> Void) {

        let collection: CollectionReference

        do {
            collection = try itemsCollection()
        } catch {
            onChange(.failure(error))
            return {}
        }

        let listener = collection.addSnapshotListener { snapshot, error in

            if let error {
                onChange(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                onChange(.success([]))
                return
            }

            let items = documents.map { document in
                self.makeItem(from: document)
            }

            onChange(.success(items))

        }

        return {
            listener.remove()
        }

    }

    // MARK: - ADD

    func addItem(_ item: Item) async throws {

        let data: [String: Any] = [

            "name": item.name,

            "quantity": item.quantity,

            "threshold": item.threshold
            

        ]

        try await itemsCollection()

            .document(item.id.uuidString)

            .setData(data)

    }

    // MARK: - UPDATE

    func updateItem(_ item: Item) async throws {

        let data: [String: Any] = [

            "name": item.name,

            "quantity": item.quantity,

            "threshold": item.threshold

        ]

        try await itemsCollection()

            .document(item.id.uuidString)

            .updateData(data)

    }

    // MARK: - DELETE

    func deleteItem(_ item: Item) async throws {

        try await itemsCollection()

            .document(item.id.uuidString)

            .delete()

    }

    private func makeItem(from document: QueryDocumentSnapshot) -> Item {

        let data = document.data()

        return Item(

            id: UUID(uuidString: document.documentID) ?? UUID(),

            name: data["name"] as? String ?? "",

            quantity: intValue(from: data["quantity"]),

            threshold: intValue(from: data["threshold"])

        )

    }

    private func intValue(from value: Any?) -> Int {

        if let value = value as? Int {
            return value
        }

        if let value = value as? NSNumber {
            return value.intValue
        }

        return 0

    }

    private func itemsCollection() throws -> CollectionReference {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw FirebaseItemRepositoryError.userNotFound
        }

        return db.collection("users")
            .document(uid)
            .collection("items")
    }

}

enum FirebaseItemRepositoryError: LocalizedError {
    case userNotFound

    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "Please log in to manage inventory items."
        }
    }
}
