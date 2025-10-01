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
    
    func addPiece(title: String, description: String?, dueDate: Date?, tags: [Tag]) {
        let piece = Piece(
            id: UUID(),
            title: title,
            createdDate: Date(),
            dueDate: dueDate,
            description: description,
            highlighted: false
        )
        
        do {
            try database.write { db in
                try Piece.insert(piece).execute(db)
                
                for tag in tags {
                    let rel = PiecesTags(id: UUID(), pieceID: piece.id, tagID: tag.id)
                    try PiecesTags.insert(rel).execute(db)
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
}
