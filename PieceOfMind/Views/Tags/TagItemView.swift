import SwiftUI

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
        .cornerRadius(6)
    }
}
