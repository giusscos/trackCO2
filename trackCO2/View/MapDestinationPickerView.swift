//
//  MapDestinationPickerView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 16/07/25.
//

import MapKit
import SwiftUI

struct MapDestinationPickerView: View {
    @Namespace var mapScope

    var activity: Activity
    
    @State private var locationManager = LocationManager()
//    @State private var position = MapCameraPosition.region(
//        MKCoordinateRegion(
//            center: CLLocationCoordinate2D(latitude: 37.334606, longitude: -122.009102), // Apple park
//            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
//        )
//    )
    @State private var position = MapCameraPosition.automatic

    @State private var searchResults = [SearchResult]()
    @State private var selectedLocation: SearchResult?
    @State private var isSheetPresented: Bool = true
    
    var body: some View {
        Map(position: $position, selection: $selectedLocation) {
            ForEach(searchResults) { result in
                Marker(coordinate: result.location) {
                    Image(systemName: "mappin")
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
    }
}

#Preview {
    MapDestinationPickerView(activity: Activity(name: "Car"))
}
