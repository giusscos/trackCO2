//
//  LocationManager.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 16/07/25.
//

import CoreLocation
import Foundation
import SwiftUI

@Observable
final class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    var lastLocation: CLLocation? = nil
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var needsSettingsRedirect: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        authorizationStatus = manager.authorizationStatus
    }

    func requestAuthorizationIfNeeded() {
        authorizationStatus = manager.authorizationStatus
        guard authorizationStatus == .notDetermined else { return }
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingIfAuthorized() {
        authorizationStatus = manager.authorizationStatus
        guard isAuthorized else { return }
        manager.startUpdatingLocation()
    }

    func requestLocation() {
        requestAuthorizationIfNeeded()
        startUpdatingIfAuthorized()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if isAuthorized {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
