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
            if let children = item.children.isEmpty ? nil : item.children {
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
    ), TagItem(
        name: "Personal",
        icon: "person.crop.circle.fill",
        color: .green,
        children: [
            TagItem(name: "Fitness", icon: "figure.run", color: .teal),
            TagItem(name: "Reading", icon: "book.fill", color: .purple),
            TagItem(name: "Shopping")
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

struct ContentView: View {
    @State private var expandedItems: Set<TagItem.ID> = []
    @State private var selection: TagItem.ID?
    @State private var showEditor = false
    @State private var tagItems: [TagItem] = sampleData

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    HierarchicalView(items: tagItems, expandedItems: $expandedItems, selection: $selection)
                }
                .listStyle(.sidebar)
                .onAppear {
                    expandedItems = Set(tagItems.map { $0.id })
                }

                Divider()

                Button("Edit") {
                    showEditor = true
                }
                .padding()
            }

        } detail: {
            if let selected = findItem(by: selection, in: tagItems) {
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
        .sheet(isPresented: $showEditor) {
            EditorWindow(tagItems: $tagItems, isPresented: $showEditor)
        }
    }

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

struct EditorWindow: View {
    @Binding var tagItems: [TagItem]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HierarchicalDragDropView(tagItems: $tagItems)
                    .padding()
                    .scrollDisabled(true)

                Divider()

                HStack {
                    Spacer()
                    Button("Save") {
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
            .navigationTitle("Edit Tags")
        }
        .frame(minWidth: 500, minHeight: 500)
    }
}

struct HierarchicalDragDropView: View {
    @Binding var tagItems: [TagItem]

    @State private var selection = Set<TagItem.ID>()

    var body: some View {
        VStack {
            // Use the AKList initializer that accepts [Item] directly
            AKList(tagItems, selection: $selection, flat: false) { (item: TagItem) in
                TagItemView(tagItem: item, isSelected: selection.contains(item.id))
                    .padding(.vertical, 4)
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
                        withAnimation {
                            moveItemIntoParent(draggedItem, parent: destinationItem)
                        }
                    } else if let destinationItem {
                        // moving item to other parent
                        moveItem(draggedItem, toParent: destinationItem, toIndex: dropIndex ?? -1)
                    } else {
                        // Moving to root
                        moveItemToRoot(draggedItem, toIndex: dropIndex ?? -1)
                    }
                    return true
                }
            )
            .akListAllowCrossSectionDrag(true)
        }
    }

    // MARK: - Move helpers (TagItem)

    func moveItemIntoParent(_ item: TagItem, parent: TagItem) {
        removeItem(item, from: &tagItems)
        appendItem(item, toParentWithID: parent.id, in: &tagItems)
    }

    func appendItem(_ item: TagItem, toParentWithID parentID: UUID, in array: inout [TagItem]) {
        for i in array.indices {
            if array[i].id == parentID {
                array[i].children.append(item)

                return
            }
            appendItem(item, toParentWithID: parentID, in: &array[i].children)
        }
    }

    func insertItem(
        _ item: TagItem,
        toParentWithID parentID: UUID,
        atIndex index: Int,
        in array: inout [TagItem]
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

    func moveItem(_ item: TagItem, toParent: TagItem, toIndex: Int) {
        removeItem(item, from: &tagItems)
        insertItem(item, toParentWithID: toParent.id, atIndex: toIndex, in: &tagItems)
    }

    func moveItemToRoot(_ item: TagItem, toIndex: Int) {
        removeItem(item, from: &tagItems)

        if toIndex == -1 {
            tagItems.append(item)
            return
        }

        let safeIndex = max(0, min(toIndex, tagItems.count))

        guard !tagItems.contains(where: { $0.id == item.id }) else { return }

        tagItems.insert(item, at: safeIndex)
    }

    func removeItem(_ item: TagItem, from array: inout [TagItem]) {
        for i in array.indices.reversed() {
            if array[i].id == item.id {
                array.remove(at: i)
                return
            }
            removeItem(item, from: &array[i].children)
        }
    }

    func findItemIndex(_ id: UUID, in array: [TagItem]) -> Int? {
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
