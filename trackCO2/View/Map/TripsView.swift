//
//  TripsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 10/07/25.
//

import MapKit
import SwiftData
import SwiftUI
import TipKit

// MARK: - Route Option

struct RouteOption: Identifiable {
    var id: UUID { activity.id }
    let activity: Activity
    let distance: Double
    let time: TimeInterval
    let polyline: MKPolyline?

    var co2Impact: Double { distance * activity.co2Emission }
}

// MARK: - TripsView

struct TripsView: View {
    @Environment(\.modelContext) var modelContext
    @Query var activities: [Activity]

    var vehicleActivities: [Activity] {
        activities.filter { $0.quantityUnit == .km }
    }

    @State private var locationManager = LocationManager.shared
    @State private var searchResults: [SearchResult] = []
    @State private var selectedLocation: SearchResult?
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var routeOptions: [RouteOption] = []
    @State private var selectedOption: RouteOption?
    @State private var isCalculating = false
    @State private var showSearchSheet = false
    @State private var nearbyResults: [SearchResult] = []
    @State private var isLoadingNearby = false
    @State private var showLocationDeniedAlert = false
    @Namespace private var searchZoom

    @State private var mapTips = TipGroup(.ordered) {
        MapPickDestinationTip()
        RouteOptionsTip()
        SaveTripTip()
    }

    var routePolyline: MKPolyline? { selectedOption?.polyline }
    var hasRoute: Bool { selectedOption != nil }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                TripMapView(
                    routePolyline: routePolyline,
                    destinationCoordinate: tappedCoordinate ?? selectedLocation?.location,
                    isCalculating: isCalculating,
                    onTap: { coordinate in
                        tappedCoordinate = coordinate
                        selectedLocation = nil
                        calculateAllRoutes(to: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 28))

                Button {
                    showSearchSheet = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(width: 48, height: 48)
                        .background(.regularMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
                }
                .matchedTransitionSource(id: "searchBtn", in: searchZoom)
                .popoverTip(mapTips.currentTip as? MapPickDestinationTip, arrowEdge: .bottom)
                .padding(16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 12)

            if hasRoute {
                routeInfoCard
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            routeOptionsSection
                .padding(.vertical, 10)
        }
        .animation(.spring(duration: 0.35), value: hasRoute)
        .animation(.spring(duration: 0.3), value: isCalculating)
        .animation(.spring(duration: 0.3), value: routeOptions.count)
        .sheet(isPresented: $showSearchSheet) {
            TripSearchSheet(
                searchResults: $searchResults,
                selectedLocation: $selectedLocation,
                nearbyResults: nearbyResults,
                isLoadingNearby: isLoadingNearby,
                userLocation: locationManager.lastLocation?.coordinate
            )
            .presentationDetents([.fraction(0.5), .large])
            .presentationDragIndicator(.visible)
            .navigationTransition(.zoom(sourceID: "searchBtn", in: searchZoom))
        }
        .onChange(of: selectedLocation) { _, newValue in
            guard let result = newValue else {
                resetRouteState()
                return
            }
            tappedCoordinate = nil
            calculateAllRoutes(to: CLLocation(latitude: result.location.latitude, longitude: result.location.longitude))
        }
        .onChange(of: searchResults) {
            if searchResults.count == 1 { selectedLocation = searchResults.first }
        }
        .onAppear {
            handleLocationAccess()
        }
        .alert("Location Access Needed", isPresented: $showLocationDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Not Now", role: .cancel) { }
        } message: {
            Text("Allow location access in Settings to see your position on the map and find nearby places.")
        }
        .onChange(of: locationManager.lastLocation) { _, newLocation in
            guard let coord = newLocation?.coordinate, nearbyResults.isEmpty, !isLoadingNearby else { return }
            isLoadingNearby = true
            Task {
                nearbyResults = (try? await LocationService.searchNearby(coordinate: coord)) ?? []
                isLoadingNearby = false
            }
        }
    }

    private func handleLocationAccess() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestAuthorizationIfNeeded()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingIfAuthorized()
            loadNearbyPlacesIfNeeded()
        case .denied, .restricted:
            showLocationDeniedAlert = true
        @unknown default:
            break
        }
    }

    private func loadNearbyPlacesIfNeeded() {
        guard let coord = locationManager.lastLocation?.coordinate, nearbyResults.isEmpty, !isLoadingNearby else { return }
        isLoadingNearby = true
        Task {
            nearbyResults = (try? await LocationService.searchNearby(coordinate: coord)) ?? []
            isLoadingNearby = false
        }
    }

    // MARK: - Subviews

    private var routeInfoCard: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(selectedOption?.distance ?? 0, specifier: "%.1f") km")
                    .font(.headline)
                    .fontWeight(.bold)
                if let time = selectedOption?.time, time > 0 {
                    Text(formatTime(time))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                let impact = selectedOption?.co2Impact ?? 0
                Text("\(abs(impact), specifier: "%.2f") kg")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(impact <= 0 ? .green : .red)
                Text(impact <= 0 ? "CO₂ saved" : "CO₂ emitted")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 8) {
                Button(action: openInAppleMaps) {
                    Image(systemName: "map.fill")
                        .frame(width: 36, height: 36)
                        .background(.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)

                Button(action: resetTrip) {
                    Image(systemName: "xmark")
                        .frame(width: 36, height: 36)
                        .background(.secondary.opacity(0.15))
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)

                Button(action: saveTrip) {
                    Image(systemName: "checkmark")
                        .frame(width: 36, height: 36)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
                .popoverTip(mapTips.currentTip as? SaveTripTip, arrowEdge: .top)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    @ViewBuilder
    private var routeOptionsSection: some View {
        if isCalculating {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Calculating routes…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(height: 44)
            .transition(.opacity)
        } else if !routeOptions.isEmpty {
            VStack(spacing: 0) {
                TipView(mapTips.currentTip as? RouteOptionsTip, arrowEdge: .bottom)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(routeOptions.enumerated()), id: \.element.id) { index, option in
                            RouteOptionCard(
                                option: option,
                                isSelected: selectedOption?.id == option.id,
                                isGreenest: index == 0
                            ) {
                                selectOption(option)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.05),
                            .init(color: .black, location: 0.95),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private func getTransportType(for type: ActivityEmissionType) -> MKDirectionsTransportType? {
        switch type {
        case .car, .motorcycle: return .automobile
        case .bus, .train: return .transit
        case .walking, .biking: return .walking
        default: return nil
        }
    }

    private func calculateAllRoutes(to destination: CLLocation) {
        guard let currentLocation = locationManager.lastLocation else { return }

        routeOptions = []
        selectedOption = nil
        isCalculating = true

        let activitiesToRoute = vehicleActivities
        guard !activitiesToRoute.isEmpty else { isCalculating = false; return }

        let straightLine = currentLocation.distance(from: destination) / 1000.0
        let source = MKMapItem(placemark: MKPlacemark(coordinate: currentLocation.coordinate))
        let dest = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))

        // Deduplicate MKDirections requests by transport type
        var transportToActivities: [UInt: [Activity]] = [:]
        var noTransportActivities: [Activity] = []

        for activity in activitiesToRoute {
            if let t = getTransportType(for: activity.type) {
                transportToActivities[t.rawValue, default: []].append(activity)
            } else {
                noTransportActivities.append(activity)
            }
        }

        var collected: [RouteOption] = noTransportActivities.map {
            RouteOption(activity: $0, distance: straightLine, time: 0, polyline: nil)
        }

        let transportEntries = Array(transportToActivities)
        var remaining = transportEntries.count

        if remaining == 0 {
            finalize(collected)
            return
        }

        for (rawType, typeActivities) in transportEntries {
            let request = MKDirections.Request()
            request.source = source
            request.destination = dest
            request.transportType = MKDirectionsTransportType(rawValue: rawType)

            MKDirections(request: request).calculate { response, _ in
                DispatchQueue.main.async {
                    if let route = response?.routes.first {
                        let d = route.distance / 1000.0
                        let t = route.expectedTravelTime
                        let poly = route.polyline
                        typeActivities.forEach { collected.append(RouteOption(activity: $0, distance: d, time: t, polyline: poly)) }
                    } else {
                        typeActivities.forEach { collected.append(RouteOption(activity: $0, distance: straightLine, time: 0, polyline: nil)) }
                    }
                    remaining -= 1
                    if remaining == 0 { finalize(collected) }
                }
            }
        }
    }

    private func finalize(_ options: [RouteOption]) {
        let sorted = options.sorted { $0.co2Impact < $1.co2Impact }
        Task { @MainActor in
            await MapPickDestinationTip().invalidate(reason: .actionPerformed)
            routeOptions = sorted
            isCalculating = false
            selectOption(sorted.first)
        }
    }

    private func selectOption(_ option: RouteOption?) {
        withAnimation(.spring(duration: 0.3)) {
            selectedOption = option
        }
        // Camera animation is handled by TripMapView reacting to routePolyline identity change
    }

    private func resetRouteState() {
        routeOptions = []
        selectedOption = nil
        isCalculating = false
    }

    private func resetTrip() {
        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
            selectedLocation = nil
            tappedCoordinate = nil
            searchResults = []
            routeOptions = []
            selectedOption = nil
            isCalculating = false
        }
        // TripMapView detects routePolyline → nil and flies back to user location
    }

    private func saveTrip() {
        guard let option = selectedOption, option.distance > 0 else { return }
        modelContext.insert(ActivityEvent(quantity: option.distance, activity: option.activity))
        recordFavoritePlace()
        withAnimation(.spring(duration: 0.45, bounce: 0.15)) {
            selectedLocation = nil
            tappedCoordinate = nil
            searchResults = []
            routeOptions = []
            selectedOption = nil
            isCalculating = false
        }
        // TripMapView detects routePolyline → nil and flies back to user location
    }

    private func openInAppleMaps() {
        guard let option = selectedOption else { return }
        let coord = tappedCoordinate ?? selectedLocation?.location
        guard let destinationCoord = coord else { return }
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoord))
        MKMapItem.openMaps(
            with: [MKMapItem.forCurrentLocation(), destination],
            launchOptions: [MKLaunchOptionsDirectionsModeKey: directionsModeKey(for: option.activity.type)]
        )
    }

    private func recordFavoritePlace() {
        let coord = tappedCoordinate ?? selectedLocation?.location
        guard let coord, let name = selectedLocation?.name else { return }
        let all = (try? modelContext.fetch(FetchDescriptor<FavoritePlace>())) ?? []
        if let existing = all.first(where: { $0.isNear(coord) }) {
            existing.visitCount += 1
            existing.lastVisited = Date()
        } else {
            modelContext.insert(FavoritePlace(
                name: name,
                subtitle: selectedLocation?.subtitle ?? "",
                latitude: coord.latitude,
                longitude: coord.longitude,
                categoryRawValue: selectedLocation?.category?.rawValue
            ))
        }
    }

    private func directionsModeKey(for type: ActivityEmissionType) -> String {
        switch type {
        case .car, .motorcycle: return MKLaunchOptionsDirectionsModeDriving
        case .bus, .train: return MKLaunchOptionsDirectionsModeTransit
        case .walking, .biking: return MKLaunchOptionsDirectionsModeWalking
        default: return MKLaunchOptionsDirectionsModeDriving
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = Int(t) % 3600 / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Route Option Card

struct RouteOptionCard: View {
    let option: RouteOption
    let isSelected: Bool
    let isGreenest: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(option.activity.type.emoji)
                        .font(.title3)
                    if isGreenest {
                        Image(systemName: "leaf.fill")
                            .font(.caption2)
                            .foregroundStyle(isSelected ? .white.opacity(0.85) : .green)
                    }
                }

                Text(option.activity.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text("\(option.distance, specifier: "%.1f") km")
                    .font(.subheadline)
                    .fontWeight(.bold)

                if option.time > 0 {
                    Text(formatTime(option.time))
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary)
                }

                co2Badge
            }
            .padding(12)
            .frame(minWidth: 110, alignment: .leading)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.borderless)
    }

    private var co2Badge: some View {
        let impact = option.co2Impact
        let isNeutral = impact <= 0
        return HStack(spacing: 2) {
            Image(systemName: isNeutral ? "arrow.down" : "arrow.up")
                .font(.caption2)
                .fontWeight(.bold)
            Text("\(abs(impact), specifier: "%.2f") kg")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundStyle(isSelected ? .white.opacity(0.9) : (isNeutral ? .green : .red))
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            (isSelected ? Color.white : (isNeutral ? Color.green : Color.red)).opacity(0.15)
        )
        .clipShape(Capsule())
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = Int(t) % 3600 / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Search Sheet

struct TripSearchSheet: View {
    @Binding var searchResults: [SearchResult]
    @Binding var selectedLocation: SearchResult?
    var nearbyResults: [SearchResult]
    var isLoadingNearby: Bool
    var userLocation: CLLocationCoordinate2D?

    @Environment(\.modelContext) var modelContext
    @Query private var favoritePlaces: [FavoritePlace]
    @State private var locationService = LocationService(completer: .init())
    @State private var search: String = ""
    @Environment(\.dismiss) var dismiss

    var pinnedPlaces: [FavoritePlace] { favoritePlaces.filter { $0.isPinned } }
    var frequentPlaces: [FavoritePlace] {
        favoritePlaces
            .filter { !$0.isPinned }
            .sorted { $0.visitCount > $1.visitCount }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search destination", text: $search)
                        .autocorrectionDisabled()
                        .onSubmit {
                            Task {
                                let results = (try? await locationService.search(with: search)) ?? []
                                searchResults = results
                                if !results.isEmpty { dismiss() }
                            }
                        }
                }
                .modifier(TextFieldGrayBackgroundColor())
                .padding(.horizontal)
                .padding(.top, 8)

                if search.isEmpty {
                    browsingList
                } else {
                    searchCompletionsList
                }
            }
            .navigationTitle("Search destination")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onChange(of: search) {
            locationService.update(queryFragment: search)
        }
    }

    // MARK: - Browsing (empty search)

    private var browsingList: some View {
        List {
            if !pinnedPlaces.isEmpty {
                Section("Pinned") {
                    ForEach(pinnedPlaces) { place in
                        PlaceRow(
                            iconName: tripSearchIconName(for: place.category),
                            iconColor: tripSearchIconColor(for: place.category),
                            title: place.name,
                            subtitle: place.subtitle,
                            badge: nil
                        ) { selectPlace(place) }
                        .swipeActions(edge: .leading) {
                            Button { place.isPinned = false } label: {
                                Label("Unpin", systemImage: "pin.slash")
                            }
                            .tint(.orange)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { modelContext.delete(place) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            if !frequentPlaces.isEmpty {
                Section("Frequent") {
                    ForEach(frequentPlaces) { place in
                        PlaceRow(
                            iconName: tripSearchIconName(for: place.category),
                            iconColor: tripSearchIconColor(for: place.category),
                            title: place.name,
                            subtitle: place.subtitle,
                            badge: "\(place.visitCount) visit\(place.visitCount == 1 ? "" : "s")"
                        ) { selectPlace(place) }
                        .swipeActions(edge: .leading) {
                            Button { place.isPinned = true } label: {
                                Label("Pin", systemImage: "pin.fill")
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { modelContext.delete(place) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            Section("Nearby") {
                if isLoadingNearby {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                } else if nearbyResults.isEmpty {
                    Text("No nearby places found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(nearbyResults) { result in
                        PlaceRow(
                            iconName: tripSearchIconName(for: result.category),
                            iconColor: tripSearchIconColor(for: result.category),
                            title: result.name ?? "Place",
                            subtitle: result.subtitle,
                            badge: distanceString(to: result.location)
                        ) { selectNearbyResult(result) }
                        .swipeActions(edge: .leading) {
                            Button { pinNearbyResult(result) } label: {
                                Label("Pin", systemImage: "pin.fill")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Search completions

    private var searchCompletionsList: some View {
        List(locationService.completions) { completion in
            PlaceRow(
                iconName: tripSearchIconName(for: completion.category),
                iconColor: tripSearchIconColor(for: completion.category),
                title: completion.title,
                subtitle: completion.subTitle.isEmpty ? nil : completion.subTitle,
                badge: completion.coordinate.flatMap { distanceString(to: $0) }
            ) {
                Task {
                    if let result = try? await locationService.search(with: "\(completion.title) \(completion.subTitle)").first {
                        searchResults = [result]
                        dismiss()
                    }
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    Task {
                        if let result = try? await locationService.search(with: "\(completion.title) \(completion.subTitle)").first {
                            pinSearchResult(result, name: completion.title, subtitle: completion.subTitle)
                        }
                    }
                } label: {
                    Label("Pin", systemImage: "pin.fill")
                }
                .tint(.blue)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Helpers

    private func distanceString(to coordinate: CLLocationCoordinate2D) -> String? {
        guard let userCoord = userLocation else { return nil }
        let userCL = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let destCL = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let km = userCL.distance(from: destCL) / 1000.0
        return km < 1 ? String(format: "%.0f m", km * 1000) : String(format: "%.1f km", km)
    }

    // MARK: - Actions

    private func selectPlace(_ place: FavoritePlace) {
        searchResults = [SearchResult(
            location: place.coordinate,
            name: place.name,
            subtitle: place.subtitle,
            category: place.category
        )]
        dismiss()
    }

    private func selectNearbyResult(_ result: SearchResult) {
        searchResults = [result]
        dismiss()
    }

    private func pinNearbyResult(_ result: SearchResult) {
        let all = (try? modelContext.fetch(FetchDescriptor<FavoritePlace>())) ?? []
        if let existing = all.first(where: { $0.isNear(result.location) }) {
            existing.isPinned = true
        } else {
            let place = FavoritePlace(
                name: result.name ?? "Place",
                subtitle: result.subtitle ?? "",
                latitude: result.location.latitude,
                longitude: result.location.longitude,
                categoryRawValue: result.category?.rawValue
            )
            place.isPinned = true
            modelContext.insert(place)
        }
    }

    private func pinSearchResult(_ result: SearchResult, name: String, subtitle: String) {
        let all = (try? modelContext.fetch(FetchDescriptor<FavoritePlace>())) ?? []
        if let existing = all.first(where: { $0.isNear(result.location) }) {
            existing.isPinned = true
        } else {
            let place = FavoritePlace(
                name: result.name ?? name,
                subtitle: result.subtitle ?? subtitle,
                latitude: result.location.latitude,
                longitude: result.location.longitude,
                categoryRawValue: result.category?.rawValue
            )
            place.isPinned = true
            modelContext.insert(place)
        }
    }
}

// MARK: - Shared place row

struct PlaceRow: View {
    let iconName: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let badge: String?
    var onTap: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(iconColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let badge {
                Text(badge)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.secondary.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }
}

// MARK: - Search icon helpers

private func tripSearchIconName(for category: MKPointOfInterestCategory?) -> String {
    guard let category else { return "mappin" }
    switch category {
    case .restaurant: return "fork.knife"
    case .cafe: return "cup.and.saucer"
    case .bakery: return "birthday.cake"
    case .store: return "bag"
    case .pharmacy: return "cross.case"
    case .school: return "graduationcap"
    case .university: return "building.columns"
    case .hotel: return "bed.double"
    case .atm, .bank: return "building"
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

private func tripSearchIconColor(for category: MKPointOfInterestCategory?) -> Color {
    guard let category else { return .gray }
    switch category {
    case .restaurant, .cafe, .bakery: return .orange
    case .park: return .green
    case .hospital, .pharmacy: return .red
    case .airport, .publicTransport: return .blue
    case .gasStation: return .yellow
    case .hotel: return .purple
    case .museum, .movieTheater, .library: return .indigo
    case .school, .university: return .teal
    default: return Color.accentColor
    }
}

#Preview {
    TripsView()
}
