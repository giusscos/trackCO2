//
//  TripMapView.swift
//  trackCO2
//

import MapKit
import SwiftUI

// MARK: - Coordinator

final class TripMapCoordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
    var onTap: (CLLocationCoordinate2D) -> Void
    var trackedPolyline: MKPolyline?
    var destinationAnnotation: MKPointAnnotation?

    init(onTap: @escaping (CLLocationCoordinate2D) -> Void) {
        self.onTap = onTap
    }

    // MARK: Gesture

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let mapView = gesture.view as? MKMapView, gesture.state == .ended else { return }
        onTap(mapView.convert(gesture.location(in: mapView), toCoordinateFrom: mapView))
    }

    // Reject touches that land directly on an annotation view so selection still works
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let mapView = gestureRecognizer.view as? MKMapView else { return true }
        let point = touch.location(in: mapView)
        for annotation in mapView.annotations {
            guard let view = mapView.view(for: annotation) else { continue }
            if view.bounds.contains(view.convert(point, from: mapView)) { return false }
        }
        return true
    }

    func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

    // MARK: MKMapViewDelegate

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let r = MKPolylineRenderer(polyline: polyline)
        r.strokeColor = .systemBlue
        r.lineWidth = 5
        r.lineCap = .round
        r.lineJoin = .round
        return r
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation { return nil }
        let id = "TripPin"
        let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
        view.annotation = annotation
        view.markerTintColor = .systemRed
        view.displayPriority = .required
        return view
    }
}

// MARK: - TripMapView

struct TripMapView: UIViewRepresentable {
    var routePolyline: MKPolyline?
    var destinationCoordinate: CLLocationCoordinate2D?
    var isCalculating: Bool
    var onTap: (CLLocationCoordinate2D) -> Void

    func makeCoordinator() -> TripMapCoordinator { TripMapCoordinator(onTap: onTap) }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic)

        // Controls
        let trackingButton = MKUserTrackingButton(mapView: mapView)
        trackingButton.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(trackingButton)

        let scaleView = MKScaleView(mapView: mapView)
        scaleView.scaleVisibility = .adaptive
        scaleView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(scaleView)

        let compass = MKCompassButton(mapView: mapView)
        compass.compassVisibility = .adaptive
        compass.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsCompass = false // use custom compass button instead
        mapView.addSubview(compass)

        NSLayoutConstraint.activate([
            trackingButton.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            trackingButton.topAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.topAnchor, constant: 12),
            compass.trailingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            compass.topAnchor.constraint(equalTo: trackingButton.bottomAnchor, constant: 8),
            scaleView.leadingAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            scaleView.bottomAnchor.constraint(equalTo: mapView.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(TripMapCoordinator.handleTap(_:)))
        tap.delegate = context.coordinator
        mapView.addGestureRecognizer(tap)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        let coordinator = context.coordinator
        coordinator.onTap = onTap

        // Route polyline — only act when identity changes
        if coordinator.trackedPolyline !== routePolyline {
            mapView.removeOverlays(mapView.overlays)
            if let polyline = routePolyline {
                mapView.addOverlay(polyline, level: .aboveRoads)
                fitCamera(mapView: mapView, to: polyline)
            } else if coordinator.trackedPolyline != nil, !isCalculating {
                // Route cleared (dismissed) — fly back to user, not when just recalculating
                flyToUser(mapView: mapView)
            }
            coordinator.trackedPolyline = routePolyline
        }

        // Destination pin
        if let coord = destinationCoordinate {
            if let existing = coordinator.destinationAnnotation {
                if existing.coordinate.latitude != coord.latitude || existing.coordinate.longitude != coord.longitude {
                    existing.coordinate = coord
                }
            } else {
                let ann = MKPointAnnotation()
                ann.coordinate = coord
                mapView.addAnnotation(ann)
                coordinator.destinationAnnotation = ann
            }
        } else if let existing = coordinator.destinationAnnotation {
            mapView.removeAnnotation(existing)
            coordinator.destinationAnnotation = nil
        }
    }

    // MARK: - Camera

    private func fitCamera(mapView: MKMapView, to polyline: MKPolyline) {
        let boundingRect = polyline.boundingMapRect
        let center = MKMapPoint(x: boundingRect.midX, y: boundingRect.midY)

        // Enforce a 500 m minimum visible radius — fixes over-zoom for short routes
        let ppm = MKMapPointsPerMeterAtLatitude(center.coordinate.latitude)
        let minRadius = 500.0 * ppm
        let minRect = MKMapRect(x: center.x - minRadius, y: center.y - minRadius,
                                width: minRadius * 2, height: minRadius * 2)

        let padding = UIEdgeInsets(top: 80, left: 40, bottom: 80, right: 40)
        mapView.setVisibleMapRect(boundingRect.union(minRect), edgePadding: padding, animated: true)
    }

    private func flyToUser(mapView: MKMapView) {
        let center = mapView.userLocation.location?.coordinate ?? mapView.region.center
        mapView.setRegion(
            MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000),
            animated: true
        )
    }
}
