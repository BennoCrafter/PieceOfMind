import SwiftUI

struct TagItem: Hashable, Identifiable {
    var id: UUID = .init()
    var name: String
    var icon: String?
    var color: Color?

    var children: [TagItem]? = nil
}
