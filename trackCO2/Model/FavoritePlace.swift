//
//  FavoritePlace.swift
//  trackCO2
//

import Foundation
import MapKit
import SwiftData

@Model
class FavoritePlace {
    var id: UUID = UUID()
    var name: String = ""
    var subtitle: String = ""
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var visitCount: Int = 1
    var lastVisited: Date = Date()
    var isPinned: Bool = false
    var categoryRawValue: String?

    init(name: String, subtitle: String = "", latitude: Double, longitude: Double, categoryRawValue: String? = nil) {
        self.name = name
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.categoryRawValue = categoryRawValue
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var category: MKPointOfInterestCategory? {
        guard let raw = categoryRawValue else { return nil }
        return MKPointOfInterestCategory(rawValue: raw)
    }

    func isNear(_ coord: CLLocationCoordinate2D, threshold: Double = 60) -> Bool {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return a.distance(from: b) < threshold
    }
}
