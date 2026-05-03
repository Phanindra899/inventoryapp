import SwiftUI

struct AddEditItemView: View {
    @ObservedObject var viewModel: ItemViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var quantityText: String
    @State private var thresholdText: String

    private let item: Item?

    init(viewModel: ItemViewModel, item: Item? = nil) {
        self.viewModel = viewModel
        self.item = item
        _name = State(initialValue: item?.name ?? "")
        _quantityText = State(initialValue: item.map { String($0.quantity) } ?? "")
        _thresholdText = State(initialValue: item.map { String($0.threshold) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Quantity", text: $quantityText)
                        .keyboardType(.numberPad)

                    TextField("Threshold", text: $thresholdText)
                        .keyboardType(.numberPad)
                }

                if let validationMessage = viewModel.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(item == nil ? "Add Item" : "Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.clearValidationMessage()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onDisappear {
                viewModel.clearValidationMessage()
            }
        }
    }

    private func save() async {
        let didSave = await viewModel.saveItem(
            existingItem: item,
            name: name,
            quantityText: quantityText,
            thresholdText: thresholdText
        )

        if didSave {
            dismiss()
        }
    }
}

struct AddEditItemView_Previews: PreviewProvider {
    static var previews: some View {
        AddEditItemView(viewModel: ItemViewModel())
    }
}
