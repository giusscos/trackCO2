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
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.title)
                                .font(.headline)
                            
                            Text(completion.subTitle)
                            
                            if let url = completion.url {
                                Link(url.absoluteString, destination: url)
                                    .lineLimit(1)
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
