import SwiftUI

struct TagItem: Hashable, Identifiable, Equatable {
    var id: UUID = .init()
    var name: String
    var icon: String?
    var color: Color?

    var children: [TagItem] = []

    static func == (lhs: TagItem, rhs: TagItem) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name && lhs.children == rhs.children
    }
}

extension TagItem: AKListItem {
    var listChildren: [any AKListItem]? {
        children.isEmpty ? nil : children
    }
}
