import SwiftUI

struct ContentView: View {
    @State private var manager = DatabaseManager()
    @State private var showAddPiece = false
    @State private var showAddTag = false

    var body: some View {
        TabView {
            // Pieces Tab
            NavigationView {
                List {
                    ForEach(manager.pieces, id: \.id) { piece in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(piece.title)
                                .font(.headline)
                            if let due = piece.dueDate {
                                Text("Due: \(due.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if let desc = piece.description {
                                Text(desc)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            VStack(alignment: .leading) {
                                let tags = manager.getTagsForPiece(piece: piece)
                                ForEach(tags, id: \.id) { tag in
                                    HStack {
                                        Text(tag.label)
                                            .padding(4)
                                            .background(tag.color.opacity(0.2))
                                            .cornerRadius(4)

                                        // Only show the icon if it exists
                                        if let iconName = tag.icon {
                                            Image(systemName: iconName)
                                                .padding(4)
                                                .background(Color.gray.opacity(0.2))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Pieces")
                .toolbar {
                    Button {
                        showAddPiece = true
                    } label: {
                        Label("Add Piece", systemImage: "plus")
                    }
                }
                .sheet(isPresented: $showAddPiece) {
                    AddPieceView(manager: manager)
                }
            }
            .tabItem { Label("Pieces", systemImage: "doc.text") }

            // Tags Tab
            NavigationView {
                List {
                    ForEach(manager.tags, id: \.id) { tag in
                        HStack {
                            Circle()
                                .fill(tag.color)
                                .frame(width: 16, height: 16)
                            Text(tag.label)
                                .font(.body)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .navigationTitle("Tags")
                .toolbar {
                    Button {
                        showAddTag = true
                    } label: {
                        Label("Add Tag", systemImage: "plus")
                    }
                }
                .sheet(isPresented: $showAddTag) {
                    AddTagView(manager: manager)
                }
            }
            .tabItem { Label("Tags", systemImage: "tag") }
        }
    }
}
