//
//  Item.swift
//  PieceOfMind
//
//  Created by Ben Baumeister on 24.08.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
