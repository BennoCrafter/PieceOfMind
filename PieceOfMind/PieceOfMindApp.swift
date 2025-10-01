//
//  PieceOfMindApp.swift
//  PieceOfMind
//
//  Created by Ben Baumeister on 24.08.25.
//

import SQLiteData
import SwiftData
import SwiftUI

@main

struct PieceOfMindApp: App {
    init() {
        try! prepareDependencies {
            try $0.bootstrapDatabase()
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}
