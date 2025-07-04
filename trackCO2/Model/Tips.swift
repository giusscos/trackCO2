//
//  Tips.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 04/07/25.
//

import Foundation
import SwiftData

@Model
class Tips {
    var id: UUID = UUID()
    var message: String
    var createdAt: Date = Date()
    
    @Relationship var activity: Activity?
    
    init(message: String, activity: Activity?) {
        self.message = message
        self.activity = activity
    }
}
