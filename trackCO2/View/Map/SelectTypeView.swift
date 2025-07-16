//
//  SelectTypeView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 16/07/25.
//

import SwiftUI
import SwiftData
import MapKit

struct SelectTypeView: View {
    @Environment(\.dismiss) var dismiss
    
    @Query var activities: [Activity]
    
    var vehicleActivities: [Activity] {
        activities.filter { $0.quantityUnit == .km }
    }
    
    var body: some View {
        NavigationStack {
            List(vehicleActivities) { activity in
                NavigationLink {
                    MapDestinationPickerView(activity: activity)
                } label: {
                    ActivityRowView(activity: activity)
                }
            }
            .navigationTitle("Select type")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close"){
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SelectTypeView()
}
