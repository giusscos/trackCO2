//
//  ActivityEvent.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import Foundation
import SwiftData

@Model
class ActivityEvent {
    var id: UUID = UUID()
    var quantity: Double = 0.0
    var createdAt: Date = Date()
    
    @Relationship var activity: Activity?
    
    init(quantity: Double) {
        self.quantity = quantity
    }
}
