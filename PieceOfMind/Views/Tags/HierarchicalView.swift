import SwiftUI

struct HierarchicalView: View {
    var items: [TagItem]
    @State var appConfig = AppConfig()

    var body: some View {
        ForEach(items) { item in
            if let children = item.children.isEmpty ? nil : item.children {
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { appConfig.expandedTagsIds.contains(item.id) },
                        set: { newValue in
                            if newValue {
                                appConfig.expandedTagsIds.insert(item.id)
                            } else {
                                appConfig.expandedTagsIds.remove(item.id)
                            }
                        }
                    )
                ) {
                    HierarchicalView(items: children)
                        .padding(.leading, 12)
                } label: {
                    TagItemView(tagItem: item, isSelected: appConfig.selectedTagId == item.id)
                        .onTapGesture {
                            appConfig.selectedTagId = item.id
                        }
                }
            } else {
                TagItemView(tagItem: item, isSelected: appConfig.selectedTagId == item.id)
                    .padding(.leading, 4)
                    .onTapGesture {
                        appConfig.selectedTagId = item.id
                    }
            }
        }
    }
}
