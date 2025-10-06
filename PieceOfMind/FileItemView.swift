import Cocoa

class TagItemView: NSTableCellView {
    private let icon = NSImageView()
    private let field = NSTextField()

    init(fileItem: FileItem) {
        super.init(frame: .zero)

        // Configure icon
        if let symbolImage = NSImage(
            systemSymbolName: fileItem.icon,
            accessibilityDescription: nil
        ) {
            var config = NSImage.SymbolConfiguration(textStyle: .body,
                                                     scale: fileItem.isFolder ? .large : .medium)
            config = config.applying(.init(paletteColors: [.systemGray]))
            icon.image = symbolImage.withSymbolConfiguration(config)
            icon.translatesAutoresizingMaskIntoConstraints = false
        }

        // Configure text
        field.stringValue = fileItem.description
        field.isEditable = false
        field.isSelectable = false
        field.isBezeled = false
        field.drawsBackground = false
        field.usesSingleLineMode = true
        field.cell?.wraps = false
        field.cell?.isScrollable = true
        field.lineBreakMode = .byTruncatingTail
        field.translatesAutoresizingMaskIntoConstraints = false

        // Stack view for icon + text
        let stack = NSStackView(views: [icon, field])
        stack.orientation = .horizontal
        stack.spacing = 12 // more spacing
        stack.alignment = .centerY
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)

        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
