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
//                print("Validate Drop: \(allowDrop) of item \(source.name) to \(destination?.name ?? "root") op=\(operation) index=\(index?.description ?? "nil")")
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
