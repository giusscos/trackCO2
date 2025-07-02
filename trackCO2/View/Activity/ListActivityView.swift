//
//  ListActivityView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftData
import SwiftUI

enum ActiveListActivitySheet: Identifiable {
    case createActivity
    case editActivity(Activity)
    
    var id: String {
        switch self {
        case .createActivity:
            return "createActivity"
        case .editActivity(let activity):
            return "editActivity-\(activity.id)"
        }
    }
}

struct ListActivityView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query private var activities: [Activity]

    @State private var activeSheet: ActiveListActivitySheet?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(activities + defaultActivities) { activity in
                        ActivityRowView(activity: activity)
                        .swipeActions {
                            Button(role: .destructive) {
                                modelContext.delete(activity)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                activeSheet = .editActivity(activity)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Activities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createActivity
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .createActivity:
                    CreateActivityView()
                case .editActivity(let activity):
                    EditActivityView(activity: activity)
                }
            }
        }
    }
}

#Preview {
    ListActivityView()
}
