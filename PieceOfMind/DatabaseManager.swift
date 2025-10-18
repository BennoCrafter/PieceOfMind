import Foundation
import SQLiteData
import SwiftUI

@Observable
class DatabaseManager {
    @ObservationIgnored
    
    @Dependency(\.defaultDatabase) var database
    
    @ObservationIgnored
    @FetchAll(Piece.order(by: \.title)) var pieces
    
    @ObservationIgnored
    @FetchAll(Tag.order(by: \.label)) var tags
    
    @ObservationIgnored
    @FetchAll(PiecesTags.order(by: \.id)) var piecesTags
    
    init() {}
    
    // MARK: - Pieces
    
    func addPiece(piece: Piece, tags: [Tag]) {
        do {
            try database.write { db in
                try Piece.insert { piece }.execute(db)
                
                for tag in tags {
                    let rel = PiecesTags(id: UUID(), pieceID: piece.id, tagID: tag.id)
                    try PiecesTags.insert { rel }.execute(db)
                }
            }
        } catch {
            print("Add piece failed: \(error)")
        }
    }
    
    // MARK: - Tags
    
    func addTag(label: String, color: Color) {
        let tag = Tag(id: UUID(), label: label, color: color, icon: nil, parent: nil)
        
        do {
            try database.write { db in
                try Tag.insert(tag).execute(db)
            }
        } catch {
            print("Add tag failed: \(error)")
        }
    }
    
    func getTagsForPiece(piece: Piece) -> [Tag] {
        // First, get all tag IDs associated with this piece
        let tagIDs = piecesTags
            .filter { $0.pieceID == piece.id }
            .map { $0.tagID }
        
        // Then, fetch the Tag objects corresponding to those IDs
        let associatedTags = tags.filter { tagIDs.contains($0.id) }
        return associatedTags
    }
    
    // MARK: - Fetch tag IDs for a specific piece
    
    func getTagsIdsForPiece(piece: Piece) -> [UUID] {
        return piecesTags
            .filter { $0.pieceID == piece.id }
            .map { $0.tagID }
    }
    
    func getTagById(_ id: UUID) -> Tag? {
        return tags
            .filter { $0.id == id }.first
    }
    
    func tagsToTagItems() -> [TagItem] {
        var byParent: [UUID?: [Tag]] = [:]
        for tag in tags {
            byParent[tag.parent, default: []].append(tag)
        }

        func buildItems(for parentId: UUID?) -> [TagItem] {
            guard var children = byParent[parentId] else { return [] }

            // Sort by position, placing nil positions last
            children.sort {
                switch ($0.position, $1.position) {
                case let (p1?, p2?): return p1 < p2
                case (nil, _?): return false
                case (_?, nil): return true
                default: return false
                }
            }

            return children.map { tag in
                TagItem(
                    id: tag.id,
                    name: tag.label,
                    icon: tag.icon,
                    color: tag.color,
                    children: buildItems(for: tag.id)
                )
            }
        }

        return buildItems(for: nil)
    }
    
    func moveTagToParentTag(moveTagId: UUID, parentTagId: UUID?, position: Int? = nil) {
        guard let moveTag = getTagById(moveTagId) else {
            print("❌ Failed to find tag to move.")
            return
        }

        withErrorReporting {
            try database.write { db in
            }
        }
    }

    func childrenFromParentId(parentId: UUID?) -> [Tag] {
        return tags
            .filter { $0.parent == parentId }
    }
}
