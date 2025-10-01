//
//  AddPieceView.swift
//  PieceOfMind
//
//  Created by Ben Baumeister on 29.09.25.
//

import SwiftUI

struct AddPieceView: View {
    @Environment(\.dismiss) var dismiss
    var manager: DatabaseManager

    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date()
    @State private var useDueDate = false
    @State private var selectedTags: Set<Tag.ID> = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Description", text: $description)
                    Toggle("Set Due Date", isOn: $useDueDate)
                    if useDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                    }
                }

                Section("Tags") {
                    ForEach(manager.tags, id: \.id) { tag in
                        MultipleSelectionRow(
                            title: tag.label,
                            isSelected: selectedTags.contains(tag.id)
                        ) {
                            if selectedTags.contains(tag.id) {
                                selectedTags.remove(tag.id)
                            } else {
                                selectedTags.insert(tag.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Piece")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let tags = manager.tags.filter { selectedTags.contains($0.id) }
                        manager.addPiece(
                            title: title,
                            description: description.isEmpty ? nil : description,
                            dueDate: useDueDate ? dueDate : nil,
                            tags: tags
                        )
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if isSelected {
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
        }
    }
}
