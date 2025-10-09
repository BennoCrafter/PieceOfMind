import SwiftUI

struct ContentView: View {
    var body: some View {
        HierarchicalDragDropView()
    }
}

// Hierarchical drag and drop example
struct HierarchicalItem: AKListItem, Identifiable, Equatable {
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
                    // Allow dropping onto any item to become its child
                    allowDrop = destination != nil
                case .above:
                    // Allow inserting as sibling if we have a destination context (destination may be nil for root)
                    allowDrop = true
                @unknown default:
                    allowDrop = false
                }
                print("Validate Drop: \(allowDrop) of item \(source.name) to \(destination?.name ?? "root") op=\(operation) index=\(index?.description ?? "nil")")
                return allowDrop
            },
            acceptDrop: { source, destination, operation, index in
                // Implement your data move. For now, just log and reject (return false).
                // You can use the helpers below to implement real moves.
                print("Accept Drop of \(source.name) to \(destination?.name ?? "root") op=\(operation) index=\(index?.description ?? "nil")")
                // Example skeleton:
                // switch operation {
                // case .on:
                //     if let dest = destination { moveItemIntoParent(source, parent: dest); return true }
                // case .above:
                //     if let dest = destination { moveItemAsSibling(source, sibling: dest); return true }
                // @unknown default:
                //     break
                // }
                return false
            }
        )
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
