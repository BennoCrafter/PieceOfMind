import SwiftUI

struct ContentView: View {
    var body: some View {
        HierarchicalDragDropView()
    }
}

// Hierarchical drag and drop example
struct HierarchicalItem: AKListItem {
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
        AKList(items, selection: $selection, flat: false) { item in
            HStack {
                Image(systemName: item.children.isEmpty ? "doc" : "folder")
                Text(item.name)
            }
            .padding(.vertical, 4)
            .akListContextMenu {
                Button("Duplicate") {
                    print("DUplicate")
                }
                Button("Delete") {
                    print("Delte")
                }
            }
        }

        .akListEnableDragDrop { draggedItem, destItem, operation in
            print("Moving item \(draggedItem.name) to \(destItem.name)")
            // Handle hierarchical moves
            if operation == .on {
                // Move into the destination item as a child
                moveItemIntoParent(draggedItem, parent: destItem)
            } else {
                // Move as sibling
                moveItemAsSibling(draggedItem, sibling: destItem)
            }
            return true
        }
        .akListAllowCrossSectionDrag(true)
    }

    func moveItemIntoParent(_ item: HierarchicalItem, parent: HierarchicalItem) {
        // Remove from current location
        removeItem(item, from: &items)

        // Add to parent's children
        if let parentIndex = findItemIndex(parent.id, in: items) {
            items[parentIndex].children.append(item)
        }
    }

    func moveItemAsSibling(_ item: HierarchicalItem, sibling: HierarchicalItem) {
        // Remove from current location
        removeItem(item, from: &items)

        // Find sibling and insert next to it
        if let siblingIndex = findItemIndex(sibling.id, in: items) {
            items.insert(item, at: siblingIndex + 1)
        }
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
            if let _ = findItemIndex(id, in: item.children) {
                return nil // Found in children, not at this level
            }
        }
        return nil
    }
}
