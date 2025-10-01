//
//  AddTagView.swift
//  PieceOfMind
//
//  Created by Ben Baumeister on 29.09.25.
//

import SwiftUI

struct AddTagView: View {
    @Environment(\.dismiss) var dismiss
    var manager: DatabaseManager

    @State private var label = ""
    @State private var color = Color.blue

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Tag Label", text: $label)
                    ColorPicker("Color", selection: $color)
                }
            }
            .navigationTitle("New Tag")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.addTag(label: label, color: color)
                        dismiss()
                    }
                    .disabled(label.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
