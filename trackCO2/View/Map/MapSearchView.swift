//
//  MapSearchView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 16/07/25.
//

import MapKit
import SwiftUI

struct MapSearchView: View {
    @State private var locationService = LocationService(completer: .init())
    @State private var search: String = ""
    
    @Binding var searchResults: [SearchResult]
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: "magnifyingglass")
                
                TextField("Search for a destination", text: $search)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task {
                            searchResults = (try? await locationService.search(with: search)) ?? []
                        }
                    }
            }
            .modifier(TextFieldGrayBackgroundColor())
            
            Spacer()
            
            List {
                ForEach(locationService.completions) { completion in
                    Button(action: { didTapOnCompletion(completion) }) {
                        HStack (alignment: .top) {
                            Group {
                                if let category = completion.category {
                                    Image(systemName: iconName(for: category))
                                } else {
                                    Image(systemName: "mappin")
                                }
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(.red)
                            .clipShape(.circle)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(completion.title)
                                    .font(.headline)
                                
                                Text(completion.subTitle)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .onChange(of: search) {
            locationService.update(queryFragment: search)
        }
        .padding()
        .interactiveDismissDisabled()
        .presentationDetents([.fraction(0.2), .large])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
    
    private func didTapOnCompletion(_ completion: SearchCompletions) {
        Task {
            if let singleLocation = try? await locationService.search(with: "\(completion.title) \(completion.subTitle)").first {
                searchResults = [singleLocation]
            }
        }
    }
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

struct TextFieldGrayBackgroundColor: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}

#Preview {
    MapSearchView(searchResults: .constant([]))
}
