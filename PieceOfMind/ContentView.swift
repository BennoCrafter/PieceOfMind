import SwiftUI

struct ContentView: View {
    var body: some View {
        HierarchicalDragDropView()
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
        .akListEnableDragDropWithIndex { draggedItem, destinationItem, operation, dropIndex in
            if let destinationItem {
                print("Moving \(draggedItem.name) to \(destinationItem.name) at index \(dropIndex ?? -1) --> operation: \(operation.rawValue)")
            } else {
                print("Moving \(draggedItem.name) to root at index \(dropIndex ?? -1)")
            }

            if operation == .on, let destinationItem {
                moveItemIntoParent(draggedItem, parent: destinationItem)
            } else if let destinationItem {
                moveItemAsSibling(draggedItem, sibling: destinationItem)
            }
            return true
        }
        .akListAllowCrossSectionDrag(true)
    }

    // MARK: - Move helpers

    func moveItemIntoParent(_ item: HierarchicalItem, parent: HierarchicalItem) {
        removeItem(item, from: &items)
        if let parentIndex = findItemIndex(parent.id, in: items) {
            items[parentIndex].children.append(item)
        }
    }

    func moveItemAsSibling(_ item: HierarchicalItem, sibling: HierarchicalItem) {
        removeItem(item, from: &items)
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
            if let idx = findItemIndex(id, in: item.children) {
                return idx
            }
        }
        return nil
    }
}
