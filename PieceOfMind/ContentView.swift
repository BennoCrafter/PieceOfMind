import SwiftUI

// MARK: - TagItemView

struct TagItemView: View {
    var tagItem: TagItem
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: tagItem.icon ?? "circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tagItem.color ?? .accentColor)
                .frame(width: 18)

            Text(tagItem.name)
                .font(.system(size: 14))
                .foregroundColor(.primary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - Hierarchical View

struct HierarchicalView: View {
    var items: [TagItem]
    @Binding var expandedItems: Set<TagItem.ID>
    @Binding var selection: TagItem.ID?

    var body: some View {
        ForEach(items) { item in
            if let children = item.children {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedItems.contains(item.id) },
                        set: { newValue in
                            if newValue {
                                expandedItems.insert(item.id)
                            } else {
                                expandedItems.remove(item.id)
                            }
                        }
                    )
                ) {
                    HierarchicalView(items: children, expandedItems: $expandedItems, selection: $selection)
                        .padding(.leading, 12)
                } label: {
                    TagItemView(tagItem: item, isSelected: selection == item.id)
                        .onTapGesture {
                            selection = item.id
                        }
                }
            } else {
                TagItemView(tagItem: item, isSelected: selection == item.id)
                    .padding(.leading, 4)
                    .onTapGesture {
                        selection = item.id
                    }
            }
        }
    }
}

// MARK: - Example Data

let sampleData: [TagItem] = [
    TagItem(
        name: "Projects",
        icon: "folder.fill",
        color: .blue,
        children: [
            TagItem(name: "Design", icon: "paintpalette.fill", color: .pink),
            TagItem(name: "Development", icon: "hammer.fill", color: .indigo),
            TagItem(name: "Marketing", icon: "megaphone.fill", color: .orange)
        ]
    ),
    TagItem(
        name: "Personal",
        icon: "person.crop.circle.fill",
        color: .green,
        children: [
            TagItem(name: "Fitness", icon: "figure.run", color: .teal),
            TagItem(name: "Reading", icon: "book.fill", color: .purple),
            TagItem(name: "Shopping")
        ]
    )
]

// MARK: - ContentView

struct ContentView: View {
    @State private var expandedItems: Set<TagItem.ID> = []
    @State private var selection: TagItem.ID?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                HierarchicalView(items: sampleData, expandedItems: $expandedItems, selection: $selection)
            }
            .listStyle(.sidebar)
            .navigationTitle("Tags")
            .onAppear {
                // expand everything by default
                expandedItems = Set(sampleData.map { $0.id })
            }
        } detail: {
            if let selected = findItem(by: selection, in: sampleData) {
                VStack {
                    Text(selected.name)
                        .font(.title2)
                        .padding()
                }
            } else {
                Text("Select a Tag")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }

    // Helper: find the selected item by ID
    func findItem(by id: TagItem.ID?, in items: [TagItem]) -> TagItem? {
        guard let id else { return nil }
        for item in items {
            if item.id == id { return item }
            if let found = findItem(by: id, in: item.children ?? []) {
                return found
            }
        }
        return nil
    }
}

// Hierarchical drag and drop example
struct HierarchicalItem: AKListItem, Equatable {
    let id: UUID
    let name: String
    var children: [HierarchicalItem]

    var listChildren: [any AKListItem]? {
        children.isEmpty ? nil : children
    }

    static func == (lhs: HierarchicalItem, rhs: HierarchicalItem) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.children == rhs.children
    }
}

struct HierarchicalDragDropView: View {
    @State private var items = [
        HierarchicalItem(id: UUID(), name: "Parent 1", children: [
            HierarchicalItem(id: UUID(), name: "Child 1.1", children: []),
            HierarchicalItem(id: UUID(), name: "Child 1.2", children: [])
        ]),
        HierarchicalItem(id: UUID(), name: "Parent 2", children: [
            HierarchicalItem(id: UUID(), name: "Child 2.1", children: [])
        ])
    ]

    @State private var selection = Set<UUID>()

    var body: some View {
        // ✅ Wrap in an AKSection
        AKList(items, selection: $selection, flat: false) { item in
            HStack {
                Image(systemName: item.children.isEmpty ? "doc" : "folder")
                Text(item.name)
            }
            .padding(.vertical, 4)
            .akListContextMenu {
                Button("Duplicate") {
                    print("Duplicate")
                }
                Button("Delete") {
                    print("Delete")
                }
            }
        }
        .akListEnableDragDropWithContext(
            dragTypes: [.string],
            validateDrop: { source, destination, operation, index in
                let allowDrop: Bool

                switch operation {
                case .on:
                    // check if dropping onto itself
                    if let dest = destination, source.id == dest.id {
                        allowDrop = false
                    } else {
                        allowDrop = true
                    }
                case .above:
                    allowDrop = true
                @unknown default:
                    allowDrop = true
                }
                return allowDrop
            },
            acceptDrop: { draggedItem, destinationItem, operation, dropIndex in
                if let destinationItem {
                    print("Moving \(draggedItem.name) to \(destinationItem.name) at index \(dropIndex ?? -1) --> operation: \(operation.rawValue)")
                } else {
                    print("Moving \(draggedItem.name) to root at index \(dropIndex ?? -1)")
                }

                if operation == .on, let destinationItem {
                    print("now")
                    withAnimation {
                        moveItemIntoParent(draggedItem, parent: destinationItem)
                    }
                } else if let destinationItem {
                    // moving item to other parent
                    print("moving item to other parent")
                    moveItem(draggedItem, toParent: destinationItem, toIndex: dropIndex ?? -1)
                } else {
                    print("Moving to root")
                    moveItemToRoot(draggedItem, toIndex: dropIndex ?? -1)
                }
                return true
            }
        )
        .akListAllowCrossSectionDrag(true)
    }

    // MARK: - Move helpers

    func moveItemIntoParent(_ item: HierarchicalItem, parent: HierarchicalItem) {
        removeItem(item, from: &items)
        appendItem(item, toParentWithID: parent.id, in: &items)
    }

    func appendItem(_ item: HierarchicalItem, toParentWithID parentID: UUID, in array: inout [HierarchicalItem]) {
        for i in array.indices {
            if array[i].id == parentID {
                array[i].children.append(item)
                return
            }
            appendItem(item, toParentWithID: parentID, in: &array[i].children)
        }
    }

    func insertItem(
        _ item: HierarchicalItem,
        toParentWithID parentID: UUID,
        atIndex index: Int,
        in array: inout [HierarchicalItem]
    ) {
        for i in array.indices {
            // Found the parent
            if array[i].id == parentID {
                // Clamp index within valid bounds (0 ... count)
                let safeIndex = max(0, min(index, array[i].children.count))

                // Prevent inserting duplicate items (optional but good safety)
                guard !array[i].children.contains(where: { $0.id == item.id }) else { return }

                array[i].children.insert(item, at: safeIndex)
                return
            }

            // Only recurse if the item has children to search
            if !array[i].children.isEmpty {
                insertItem(item, toParentWithID: parentID, atIndex: index, in: &array[i].children)
            }
        }
    }

    func moveItem(_ item: HierarchicalItem, toParent: HierarchicalItem, toIndex: Int) {
        removeItem(item, from: &items)
        insertItem(item, toParentWithID: toParent.id, atIndex: toIndex, in: &items)
    }

    func moveItemToRoot(_ item: HierarchicalItem, toIndex: Int) {
        removeItem(item, from: &items)

        if toIndex == -1 {
            items.append(item)
            return
        }

        let safeIndex = max(0, min(toIndex, items.count))

        guard !items.contains(where: { $0.id == item.id }) else { return }

        items.insert(item, at: safeIndex)
    }

    func removeItem(_ item: HierarchicalItem, from array: inout [HierarchicalItem]) {
        for i in array.indices.reversed() {
            if array[i].id == item.id {
                array.remove(at: i)
                return
            }
            removeItem(item, from: &array[i].children)
        }
    }

    func findItemIndex(_ id: UUID, in array: [HierarchicalItem]) -> Int? {
        for (index, item) in array.enumerated() {
            if item.id == id {
                return index
            }
            if let idx = findItemIndex(id, in: item.children) {
                return idx
            }
        }
        return nil
    }
}
