//
//  TripMapView.swift
//  trackCO2
//

import MapKit
import SwiftUI

// MARK: - Annotation kinds

final class TripPointAnnotation: MKPointAnnotation {
    enum Kind { case origin, destination }
    let kind: Kind

    init(kind: Kind, coordinate: CLLocationCoordinate2D, title: String?) {
        self.kind = kind
        super.init()
        self.coordinate = coordinate
        self.title = title
    }
}

// MARK: - Coordinator

final class TripMapCoordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
    var onTap: (CLLocationCoordinate2D) -> Void
    var trackedPolyline: MKPolyline?
    var originAnnotation: TripPointAnnotation?
    var destinationAnnotation: TripPointAnnotation?

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

        let trip = annotation as? TripPointAnnotation
        let id = trip?.kind == .origin ? "TripOriginPin" : "TripDestinationPin"
        let view = (mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView)
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
        view.annotation = annotation
        if let trip {
            view.markerTintColor = trip.kind == .origin ? .systemGreen : .systemRed
            view.glyphImage = UIImage(systemName: trip.kind == .origin ? "figure.walk" : "flag.fill")
        } else {
            view.markerTintColor = .systemRed
            view.glyphImage = nil
        }
        view.displayPriority = .required
        return view
    }
}

// MARK: - TripMapView

struct TripMapView: UIViewRepresentable {
    var routePolyline: MKPolyline?
    var originCoordinate: CLLocationCoordinate2D?
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

        updatePin(
            on: mapView,
            coordinator: coordinator,
            kind: .origin,
            coordinate: originCoordinate,
            title: String(localized: "Start"),
            annotation: &coordinator.originAnnotation
        )
        updatePin(
            on: mapView,
            coordinator: coordinator,
            kind: .destination,
            coordinate: destinationCoordinate,
            title: String(localized: "Selected"),
            annotation: &coordinator.destinationAnnotation
        )
    }

    private func updatePin(
        on mapView: MKMapView,
        coordinator: TripMapCoordinator,
        kind: TripPointAnnotation.Kind,
        coordinate: CLLocationCoordinate2D?,
        title: String,
        annotation: inout TripPointAnnotation?
    ) {
        if let coord = coordinate {
            if let existing = annotation {
                if existing.coordinate.latitude != coord.latitude || existing.coordinate.longitude != coord.longitude {
                    existing.coordinate = coord
                }
            } else {
                let ann = TripPointAnnotation(kind: kind, coordinate: coord, title: title)
                mapView.addAnnotation(ann)
                annotation = ann
            }
        } else if let existing = annotation {
            mapView.removeAnnotation(existing)
            annotation = nil
        }
    }

    // MARK: - Camera

    private func fitCamera(mapView: MKMapView, to polyline: MKPolyline) {
        let boundingRect = polyline.boundingMapRect
        guard !boundingRect.isNull, !boundingRect.isEmpty else { return }

        let center = MKMapPoint(x: boundingRect.midX, y: boundingRect.midY)
        guard CLLocationCoordinate2DIsValid(center.coordinate) else { return }

        // Enforce a 500 m minimum visible radius — fixes over-zoom for short routes
        let ppm = MKMapPointsPerMeterAtLatitude(center.coordinate.latitude)
        guard ppm.isFinite, ppm > 0 else { return }

        let minRadius = 500.0 * ppm
        let minRect = MKMapRect(x: center.x - minRadius, y: center.y - minRadius,
                                width: minRadius * 2, height: minRadius * 2)
        let visible = boundingRect.union(minRect)
        guard !visible.isNull, !visible.isEmpty else { return }

        let padding = UIEdgeInsets(top: 80, left: 40, bottom: 80, right: 40)
        // Defer camera change so it doesn't race sheet dismissal / annotation updates
        DispatchQueue.main.async {
            mapView.setVisibleMapRect(visible, edgePadding: padding, animated: true)
        }
    }

    private func flyToUser(mapView: MKMapView) {
        let center = mapView.userLocation.location?.coordinate ?? mapView.region.center
        guard CLLocationCoordinate2DIsValid(center) else { return }
        DispatchQueue.main.async {
            mapView.setRegion(
                MKCoordinateRegion(center: center, latitudinalMeters: 1000, longitudinalMeters: 1000),
                animated: true
            )
        }
    }
}
