import SQLiteData
import SwiftUI

struct ContentView: View {
    @Dependency(\.defaultDatabase) var database

    @Bindable var databaseManager: DatabaseManager

    @State private var appConfig = AppConfig()
    @State private var showEditor = false
    private var tagItems: [TagItem] { databaseManager.tagsToTagItems() }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $appConfig.selectedTagId) {
                    HierarchicalView(items: tagItems)
                }
                .listStyle(.sidebar)
                .onAppear {
                    print(appConfig.expandedTagsIds)
                }

                Divider()

                Button("Edit") {
                    showEditor = true
                }
                .padding()
            }

        } detail: {
            if let selected = findItem(by: appConfig.selectedTagId, in: tagItems) {
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
            EditorWindow(dbManager: databaseManager, tagItems: tagItems, isPresented: $showEditor)
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
    @Bindable var dbManager: DatabaseManager
    var tagItems: [TagItem]
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HierarchicalDragDropView(dbManager: dbManager, tagItems: tagItems)
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
    @Bindable var dbManager: DatabaseManager
    var tagItems: [TagItem]

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
                            dbManager.moveTagToParentTag(moveTagId: draggedItem.id, parentTagId: destinationItem.id, position: dropIndex)
                        }
                    } else if let destinationItem {
                        // moving item to other parent
                        dbManager.moveTagToParentTag(moveTagId: draggedItem.id, parentTagId: destinationItem.id, position: dropIndex)

                    } else {
                        // Moving to root
                        dbManager.moveTagToParentTag(moveTagId: draggedItem.id, parentTagId: nil, position: dropIndex.map { $0 })
                    }
                    return true
                }
            )
            .akListAllowCrossSectionDrag(true)
        }
    }

    // MARK: - Move helpers (TagItem)
}
