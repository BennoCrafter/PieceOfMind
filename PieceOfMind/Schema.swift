import Foundation
import OSLog
import SQLiteData
import SwiftUI

@Table
struct Piece: Identifiable, Hashable {
    @Column(primaryKey: true)

    let id: UUID
    var title: String
    var createdDate: Date
    var dueDate: Date?
    var description: String?
    var highlighted: Bool?
}

@Table
struct Tag: Hashable, Identifiable {
    @Column(primaryKey: true)
    let id: UUID
    var label: String
    @Column(as: Color.HexRepresentation.self)
    var color: Color = Self.defaultColor
    var icon: String?
    /// Just a UUID reference, not a foreign key
    var parent: UUID?
    /// positon relative to parent
    var position: Int?

    static var defaultColor: Color {
        Color(red: 0x4a / 255, green: 0x99 / 255, blue: 0xef / 255)
    }
}

/// Join table to link multiple tags to a piece
@Table("pieces_tags")
struct PiecesTags {
    @Column(primaryKey: true)
    let id: UUID

    let pieceID: Piece.ID
    let tagID: Tag.ID
}

extension DependencyValues {
    mutating func bootstrapDatabase() throws {
        @Dependency(\.context) var context
        let database = try SQLiteData.defaultDatabase()
        logger.debug(
            """
            App database
            open "\(database.path)"
            """
        )
        let defaultTagColor = Color.HexRepresentation(queryOutput: Tag.defaultColor).hexValue

        var migrator = DatabaseMigrator()
        #if DEBUG
        migrator.eraseDatabaseOnSchemaChange = true
        #endif

        migrator.registerMigration("Create tables") { db in
            try #sql(
                """
                CREATE TABLE "pieces" (
                    "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "title" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT "No title",
                    "createdDate" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT (datetime()),
                    "dueDate" TEXT,
                    "description" TEXT,
                    "highlighted" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "tags" (
                    "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "label" TEXT NOT NULL,
                    "color" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT \(raw: defaultTagColor ?? 0),
                    "icon" TEXT,
                    "parent" TEXT,
                    "position" INTEGER
                ) STRICT
                """
            )
            .execute(db)

            try #sql(
                """
                CREATE TABLE "pieces_tags" (
                    "id" TEXT PRIMARY KEY NOT NULL DEFAULT (uuid()),
                    "pieceID" TEXT NOT NULL REFERENCES "pieces"("id") ON DELETE CASCADE,
                    "tagID"   TEXT NOT NULL REFERENCES "tags"("id") ON DELETE CASCADE
                ) STRICT;
                """
            )
            .execute(db)
        }
//        migrator.registerMigration("Insert example data") { db in
//            try db.execute(
//                sql: """
//                INSERT INTO tags (id, label, color, icon, parent)
//                VALUES
//                    (uuid(), 'School', '\(Color.HexRepresentation(queryOutput: Color.fromHex("#4caf50")).hexValue ?? 0)', 'book', NULL),
//                    (uuid(), 'Work',   '\(Color.HexRepresentation(queryOutput: Color.fromHex("#7EB6FE")).hexValue ?? 0)', 'briefcase', NULL);
//                """
//            )
//
//            try db.execute(
//                sql: """
//                INSERT INTO pieces (id, title, createdDate, dueDate, description, highlighted)
//                VALUES
//                    (uuid(), 'Math Homework', datetime('now'), datetime('now', '+2 days'), 'Finish exercises 5–10', 1),
//                    (uuid(), 'Project Report', datetime('now'), datetime('now', '+7 days'), 'Draft introduction and conclusion', 0);
//                """
//            )
//
//            try db.execute(
//                sql: """
//                INSERT INTO pieces_tags (id, pieceID, tagID)
//                    SELECT uuid(), pieces.id, tags.id
//                    FROM pieces, tags
//                    WHERE (pieces.title = 'Math Homework' AND tags.label = 'School')
//                        OR (pieces.title = 'Project Report' AND tags.label = 'Work');
//                """
//            )
//        }
        try migrator.migrate(database)
        defaultDatabase = database
        defaultSyncEngine = try SyncEngine(
            for: defaultDatabase,
            tables: Piece.self, Tag.self, PiecesTags.self
        )
    }
}

private let logger = Logger(subsystem: "PieceOfMind", category: "Database")
