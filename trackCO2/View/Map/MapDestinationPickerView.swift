//
//  MapDestinationPickerView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 16/07/25.
//

import MapKit
import SwiftUI
import SwiftData

struct MapDestinationPickerView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var activity: Activity
    
    @State private var locationManager = LocationManager()
    @State private var position = MapCameraPosition.automatic
    @State private var searchResults = [SearchResult]()
    @State private var selectedLocation: SearchResult?
    @State private var isSheetPresented: Bool = true
    @State private var showingSaveAlert = false
    @State private var calculatedDistance: Double = 0.0
    @State private var estimatedTime: TimeInterval = 0.0
    
    var body: some View {
        NavigationStack {
            Map(position: $position, selection: $selectedLocation) {
                ForEach(searchResults) { result in
                    Marker(coordinate: result.location) {
                        if let category = result.category {
                            Image(systemName: iconName(for: category))
                        } else {
                            Image(systemName: "mappin")
                        }
                    }
                    .tag(result)
                }
            }
            .mapControls {
                MapScaleView()
                MapCompass()
                MapUserLocationButton()
            }
            .sheet(isPresented: $isSheetPresented) {
                MapSearchView(searchResults: $searchResults)
            }
            .onChange(of: selectedLocation) {
                isSheetPresented = selectedLocation == nil
            }
            .onChange(of: searchResults) {
                if let firstResult = searchResults.first, searchResults.count == 1 {
                    selectedLocation = firstResult
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        calculateDistanceAndShowAlert()
                    }
                    .disabled(selectedLocation == nil)
                }
            }
            .alert("Save Trip", isPresented: $showingSaveAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Save") {
                    saveActivityEvent()
                }
            } message: {
                if estimatedTime > 0 {
                    Text("Distance: \(calculatedDistance, specifier: "%.1f") km\nEstimated time: \(formatTime(estimatedTime))\nType: \(activity.name)")
                } else {
                    Text("Distance: \(calculatedDistance, specifier: "%.1f") km\nType: \(activity.name)")
                }
            }
        }
    }
    
    private func calculateDistanceAndShowAlert() {
        guard let selectedLocation = selectedLocation,
              let currentLocation = locationManager.lastLocation else {
            return
        }
        
        let destination = CLLocation(latitude: selectedLocation.location.latitude, longitude: selectedLocation.location.longitude)
        
        // Check if activity type supports route calculation
        if let transportType = getTransportType(for: activity.type) {
            calculateRoute(from: currentLocation, to: destination, transportType: transportType)
        } else {
            // Use straight line distance for non-transport activities
            calculatedDistance = currentLocation.distance(from: destination) / 1000.0
            estimatedTime = 0.0
            showingSaveAlert = true
        }
    }
    
    private func getTransportType(for activityType: ActivityEmissionType) -> MKDirectionsTransportType? {
        switch activityType {
        case .car, .motorcycle:
            return .automobile
        case .bus, .train:
            return .transit
        case .walking:
            return .walking
        case .biking:
            return .walking // MKDirections doesn't have biking, use walking as approximation
        default:
            return nil // For airplane, boat, food, energy, etc.
        }
    }
    
    private func calculateRoute(from origin: CLLocation, to destination: CLLocation, transportType: MKDirectionsTransportType) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
        request.transportType = transportType
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                if let route = response?.routes.first {
                    calculatedDistance = route.distance / 1000.0 // Convert to km
                    estimatedTime = route.expectedTravelTime
                } else {
                    // Fallback to straight line distance
                    calculatedDistance = origin.distance(from: destination) / 1000.0
                    estimatedTime = 0.0
                }
                showingSaveAlert = true
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func saveActivityEvent() {
        guard let _ = selectedLocation else { return }
        
        let activityEvent = ActivityEvent(quantity: calculatedDistance, activity: activity)
        modelContext.insert(activityEvent)
        
        dismiss()
    }
    
    private func iconName(for category: MKPointOfInterestCategory) -> String {
        switch category {
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .bakery: return "birthday.cake"
        case .store: return "bag"
        case .pharmacy: return "cross.case"
        case .school: return "graduationcap"
        case .university: return "building.columns"
        case .hotel: return "bed.double"
        case .atm: return "banknote"
        case .bank: return "building"
        case .hospital: return "cross"
        case .park: return "leaf"
        case .museum: return "paintpalette"
        case .movieTheater: return "film"
        case .gasStation: return "fuelpump"
        case .library: return "books.vertical"
        case .postOffice: return "envelope"
        case .police: return "shield.lefthalf.filled"
        case .fireStation: return "flame"
        case .publicTransport: return "bus"
        case .airport: return "airplane"
        case .parking: return "parkingsign.circle"
        default: return "mappin"
        }
    }
}

#Preview {
    MapDestinationPickerView(activity: Activity(name: "Car"))
}
