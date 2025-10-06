//  ViewModel.swift
//  OutlineViewExample — Refactored
//
//  Fixed logic issues and crash bugs

import Cocoa
import OutlineView

func sampleDataSource() -> OutlineSampleViewModel {
    let fido = FileItem(fileName: "Fido")
    let chip = FileItem(fileName: "Chip")
    let rover = FileItem(fileName: "Rover")
    let spot = FileItem(fileName: "Spot")

    let fluffy = FileItem(fileName: "Fluffy")
    let fang = FileItem(fileName: "Fang")
    let tootsie = FileItem(fileName: "Tootsie")
    let milo = FileItem(fileName: "Milo")

    let bart = FileItem(fileName: "Bart")
    let leo = FileItem(fileName: "Leo")
    let lucy = FileItem(fileName: "Lucy")
    let dia = FileItem(fileName: "Dia")
    let templeton = FileItem(fileName: "Templeton")
    let chewy = FileItem(fileName: "Chewy")
    let pizza = FileItem(fileName: "Pizza")

    let dogsFolder = FileItem(folderName: "Dogs")
    let catsFolder = FileItem(folderName: "Cats")
    let otherFolder = FileItem(folderName: "Other")
    let ratsFolder = FileItem(folderName: "Rats")
    let fishFolder = FileItem(folderName: "Fish")
    let turtlesFolder = FileItem(folderName: "Turtles")

    let roots = [
        dogsFolder,
        catsFolder,
        otherFolder
    ]

    let childDirectory: [FileItem: [FileItem]] = [
        dogsFolder: [fido, chip, rover, spot],
        catsFolder: [fluffy, fang, tootsie, milo],
        otherFolder: [ratsFolder, fishFolder, turtlesFolder, chewy, pizza],
        ratsFolder: [templeton, leo, bart],
        fishFolder: [dia, lucy],
        turtlesFolder: []
    ]

    let childlessItems = [fido, chip, rover, spot, fluffy, fang, tootsie, milo, bart, leo, lucy, dia, templeton, chewy, pizza]
    let theChilds = childDirectory.map { ($0.key, $0.value) } + childlessItems.map { ($0, nil) }

    return OutlineSampleViewModel(rootData: roots, childrenDirectory: theChilds)
}

extension NSPasteboard.PasteboardType {
    static var outlineViewItem: Self { .init("OutlineView.OutlineItem") }
}

struct FileItem: Hashable, Identifiable, CustomStringConvertible {
    var name: String
    var isFolder: Bool

    var id: String { name }

    var description: String { name }

    var icon: String { isFolder ? "folder" : "text.document" }

    init(folderName: String) { self.name = folderName; self.isFolder = true }
    init(fileName: String) { self.name = fileName; self.isFolder = false }

    static func == (lhs: FileItem, rhs: FileItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Responsible for all hierarchical data operations (removes, inserts, queries).
final class FileHierarchyManager {
    private(set) var rootData: [FileItem]
    /// tuple: (item, children?) -- children == nil means item is a file
    private(set) var dataAndChildren: [(item: FileItem, children: [FileItem]?)]

    init(rootData: [FileItem], childrenDirectory: [(FileItem, [FileItem]?)]) {
        self.rootData = rootData
        self.dataAndChildren = childrenDirectory
    }

    // MARK: - Queries

    func children(of item: FileItem) -> [FileItem]? {
        dataAndChildren.first(where: { $0.item.id == item.id })?.children
    }

    func item(withID id: String) -> FileItem? {
        dataAndChildren.first(where: { $0.item.id == id })?.item
    }

    func parent(of item: FileItem) -> FileItem? {
        dataAndChildren.first(where: { $0.children?.contains(item) ?? false })?.item
    }

    func indexOfItemInParent(_ item: FileItem) -> (parent: FileItem?, index: Int)? {
        if let rootIndex = rootData.firstIndex(of: item) {
            return (nil, rootIndex)
        }
        if let (parentEntryIndex, _) = dataAndChildren.enumerated().first(where: { $0.element.children?.contains(item) ?? false }) {
            let parent = dataAndChildren[parentEntryIndex].item
            let siblings = dataAndChildren[parentEntryIndex].children!
            let idx = siblings.firstIndex(of: item)!
            return (parent, idx)
        }
        return nil
    }

    func isDescendant(_ item: FileItem, of possibleAncestor: FileItem) -> Bool {
        var current = parent(of: item)
        while let c = current {
            if c == possibleAncestor { return true }
            current = parent(of: c)
        }
        return false
    }

    // MARK: - Mutations

    /// Remove item from wherever it currently is. Returns previous (parent, index) if found.
    @discardableResult
    func remove(_ item: FileItem) -> (parent: FileItem?, index: Int)? {
        if let rootIdx = rootData.firstIndex(of: item) {
            rootData.remove(at: rootIdx)
            return (nil, rootIdx)
        }

        if let parentIndex = dataAndChildren.firstIndex(where: { $0.children?.contains(item) ?? false }) {
            if var children = dataAndChildren[parentIndex].children {
                let idx = children.firstIndex(of: item)!
                children.remove(at: idx)
                dataAndChildren[parentIndex].children = children
                return (dataAndChildren[parentIndex].item, idx)
            }
        }

        return nil
    }

    /// Insert item into a parent (nil = root) at given index. If index is nil, append.
    func insert(_ item: FileItem, into parent: FileItem?, at index: Int?) {
        if let parent = parent {
            // Insert into folder
            if let dataIdx = dataAndChildren.firstIndex(where: { $0.item.id == parent.id }) {
                if dataAndChildren[dataIdx].children == nil {
                    // If the parent is a file (shouldn't happen) convert to folder with empty children
                    dataAndChildren[dataIdx].children = []
                }
                if let insertIndex = index, insertIndex <= dataAndChildren[dataIdx].children!.count {
                    dataAndChildren[dataIdx].children!.insert(item, at: insertIndex)
                } else {
                    dataAndChildren[dataIdx].children!.append(item)
                }
            } else {
                // parent not registered in dataAndChildren — add it
                dataAndChildren.append((parent, [item]))
            }
        } else {
            // Insert into root
            if let insertIndex = index, insertIndex <= rootData.count {
                rootData.insert(item, at: insertIndex)
            } else {
                rootData.append(item)
            }
        }

        // Ensure the item itself exists in dataAndChildren (register it)
        if dataAndChildren.firstIndex(where: { $0.item.id == item.id }) == nil {
            dataAndChildren.append((item, item.isFolder ? [] : nil))
        }
    }

    /// Replace a file item (leaf) with a new folder containing the original file.
    /// Returns the new folder.
    @discardableResult
    func replaceFileWithFolder(file: FileItem, folderName: String) -> FileItem {
        let newFolder = FileItem(folderName: folderName)

        // Replace in root if needed
        if let rootIdx = rootData.firstIndex(of: file) {
            rootData[rootIdx] = newFolder
        }

        // Replace in parent's children if needed
        if let parentIndex = dataAndChildren.firstIndex(where: { $0.children?.contains(file) ?? false }) {
            var children = dataAndChildren[parentIndex].children!
            if let fileIdx = children.firstIndex(of: file) {
                children[fileIdx] = newFolder
                dataAndChildren[parentIndex].children = children
            }
        }

        // Remove the old file entry from dataAndChildren completely
        dataAndChildren.removeAll(where: { $0.item.id == file.id })

        // Add the file back as a leaf (with nil children since it's a file)
        dataAndChildren.append((file, nil))

        // Add the new folder with the file as its child
        dataAndChildren.append((newFolder, [file]))

        return newFolder
    }

    /// Replace an empty folder with a new file. Returns the new file.
    /// Assumes folder is empty; otherwise, children are discarded.
    @discardableResult
    func replaceFolderWithFile(folder: FileItem) -> FileItem {
        // Create a new file with the same name as the folder
        let newFile = FileItem(fileName: folder.name)

        // Replace in root if needed
        if let rootIdx = rootData.firstIndex(of: folder) {
            rootData[rootIdx] = newFile
        }

        // Replace in parent's children if needed
        if let parentIndex = dataAndChildren.firstIndex(where: { $0.children?.contains(folder) ?? false }) {
            var children = dataAndChildren[parentIndex].children!
            if let folderIdx = children.firstIndex(of: folder) {
                children[folderIdx] = newFile
                dataAndChildren[parentIndex].children = children
            }
        }

        // Remove the folder from dataAndChildren
        if let idx = dataAndChildren.firstIndex(where: { $0.item.id == folder.id }) {
            dataAndChildren.remove(at: idx)
        }

        // Add the new file to dataAndChildren if not already present
        if dataAndChildren.firstIndex(where: { $0.item.id == newFile.id }) == nil {
            dataAndChildren.append((newFile, nil))
        }

        return newFile
    }

    // For debugging / external use
    func dumpState() {
        print("Root:", rootData.map { $0.name })
        for (item, children) in dataAndChildren {
            print("Item: \(item.name) (folder: \(item.isFolder)) -> children: \(children?.map { $0.name } ?? [])")
        }
    }
}

class OutlineSampleViewModel: ObservableObject {
    @Published private(set) var manager: FileHierarchyManager

    var pasteboardTypes: [NSPasteboard.PasteboardType] {
        [.outlineViewItem, .fileURL, .fileContents, .string]
    }

    init(rootData: [FileItem], childrenDirectory: [(FileItem, [FileItem]?)]) {
        self.manager = FileHierarchyManager(rootData: rootData, childrenDirectory: childrenDirectory)
    }

    var rootData: [FileItem] { manager.rootData }

    func childrenOfItem(_ item: FileItem) -> [FileItem]? { manager.children(of: item) }
}

// MARK: - Drop handling

extension OutlineSampleViewModel: DropReceiver {
    func readPasteboard(item: NSPasteboardItem) -> DraggedItem<FileItem>? {
        guard let pasteboardType = item.availableType(from: pasteboardTypes) else { return nil }

        var result: FileItem? = nil
        switch pasteboardType {
        case .outlineViewItem:
            let encodedData = item.data(forType: pasteboardType)
            let decodedID = encodedData.flatMap { try? JSONDecoder().decode(String.self, from: $0) }
            result = decodedID.flatMap { manager.item(withID: $0) }
        case .fileURL:
            let filePath = item.string(forType: pasteboardType)
            let fileUrl = filePath.flatMap { URL(string: $0) }
            let fileName = fileUrl?.standardized.lastPathComponent
            let isDirectory = (try? fileUrl?.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            result = isDirectory ? fileName.map(FileItem.init(folderName:)) : fileName.map(FileItem.init(fileName:))
        case .fileContents:
            let fileData = item.data(forType: pasteboardType) ?? Data()
            let sizeOfData = Int64(fileData.count)
            let someFileName = ByteCountFormatter.string(fromByteCount: sizeOfData, countStyle: .file)
            result = FileItem(fileName: someFileName)
        case .string:
            let stringValue = item.string(forType: pasteboardType)
            result = stringValue.map(FileItem.init(fileName:))
        default:
            break
        }

        return result.map { ($0, pasteboardType) }
    }

    func validateDrop(target: DropTarget<FileItem>) -> ValidationResult<FileItem> {
        guard let singleDraggedItem = target.items.first else { return .deny }

        // can't drop item onto itself
        if let into = target.intoElement, into == singleDraggedItem.item { return .deny }

        if let into = target.intoElement {
            // Allow dropping onto files (will create a folder)
            if !into.isFolder { return .move }

            // if into is a descendant of dragged item, deny (can't move into own descendant)
            if manager.isDescendant(into, of: singleDraggedItem.item) { return .deny }
        }

        // compute target children array for self-copy checks
        let targetChildren: [FileItem]
        if target.intoElement == nil {
            targetChildren = manager.rootData
        } else if let children = manager.children(of: target.intoElement!) {
            targetChildren = children
        } else {
            // Target has no children (it's a file), allow move
            return .move
        }

        // Deny moving onto same spot
        if !targetChildren.isEmpty,
           let dropIndex = target.childIndex,
           let existingIndex = targetChildren.firstIndex(of: singleDraggedItem.item),
           existingIndex == dropIndex || existingIndex == dropIndex - 1
        {
            return .deny
        }

        // root redirect behaviour
        if target.intoElement == nil,
           target.childIndex == nil
        {
            if singleDraggedItem.type == .outlineViewItem {
                return .moveRedirect(item: nil, childIndex: manager.rootData.count)
            } else {
                return .copyRedirect(item: nil, childIndex: manager.rootData.count)
            }
        }

        // if into is unexpanded but has childIndex, redirect to append
        if let into = target.intoElement,
           !target.isItemExpanded(into),
           target.childIndex != nil
        {
            if singleDraggedItem.type == .outlineViewItem {
                return .moveRedirect(item: into, childIndex: nil)
            } else {
                return .copyRedirect(item: into, childIndex: nil)
            }
        }

        return .move
    }

    func acceptDrop(target: DropTarget<FileItem>) -> Bool {
        guard let dragged = target.items.first else { return false }
        let movedItem = dragged.item
        let previousLocation = manager.indexOfItemInParent(movedItem)

        // Check if dropping onto a file -> create a new folder
        if let intoItem = target.intoElement, !intoItem.isFolder {
            // Store previous location before removing

            // Remove moved item from its previous location
            if previousLocation != nil {
                _ = manager.remove(movedItem)
            }

            // Create a new folder with the target file's name
            // This automatically adds the original file as a child
            let newFolder = manager.replaceFileWithFolder(file: intoItem, folderName: intoItem.name)

            // Insert the moved item as a child of the new folder
            manager.insert(movedItem, into: newFolder, at: nil)

            objectWillChange.send()
            return true
        }

        // Normal drop handling: store location before removing

        // Remove from old location
        if previousLocation != nil {
            _ = manager.remove(movedItem)
        }

        // Calculate insert index adjustment if moving within same parent
        var subtractFromInsertIndex = 0
        if let prev = previousLocation,
           prev.parent == target.intoElement,
           let newIndex = target.childIndex,
           newIndex > prev.index
        {
            subtractFromInsertIndex = 1
        }

        // Insert into new location
        if let into = target.intoElement {
            // into is a folder
            if let basicIndex = target.childIndex {
                let insertIndex = basicIndex - subtractFromInsertIndex
                manager.insert(movedItem, into: into, at: insertIndex)
            } else {
                manager.insert(movedItem, into: into, at: nil)
            }
        } else {
            // into root
            if let basicIndex = target.childIndex {
                let insertIndex = basicIndex - subtractFromInsertIndex
                manager.insert(movedItem, into: nil, at: insertIndex)
            } else {
                manager.insert(movedItem, into: nil, at: nil)
            }
        }

        objectWillChange.send()
        return true
    }
}
