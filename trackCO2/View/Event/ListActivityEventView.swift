//
//  ListActivityEventView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftData
import SwiftUI

struct ListActivityEventView: View {
    @Query var activities: [Activity]
    
    @State private var co2EmissionsToAdd: Double = 0.0
    
    @State private var selectedTab: String?
    
    var body: some View {
        VStack {
            VStack (alignment: .leading) {
                Text("Add Event")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select an activity and insert the amount")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            TabView (selection: $selectedTab) {
                ForEach(activities + defaultActivities) { activity in
                    ActivityEventTabView(activity: activity)
                        .tag(activity.id.uuidString)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            HStack {
                Button {
                    withAnimation {
                        co2EmissionsToAdd -= 0.1
                    }
                } label: {
                    Label("Minus", systemImage: "minus")
                        .font(.title)
                        .fontWeight(.bold)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                
                Text("\(co2EmissionsToAdd, specifier: "%.2f")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .contentTransition(.numericText(value: co2EmissionsToAdd))
                
                Button {
                    withAnimation {
                        co2EmissionsToAdd += 0.1
                    }
                } label: {
                    Label("Plus", systemImage: "plus")
                        .font(.title)
                        .fontWeight(.bold)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
            }
            .padding(.vertical, 24)
            
            Button {
                let allActivities = activities + defaultActivities
                let selectedActivity = allActivities.first { $0.id.uuidString == selectedTab }
                
                if let selectedActivity = selectedActivity {
                    print(selectedActivity.name)
                }
            } label: {
                Text("Add event")
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .foregroundStyle(.background)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .tint(.primary)
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onAppear() {
            if activities.isEmpty, let activity = defaultActivities.first {
                selectedTab = activity.id.uuidString
            } else if let activity = activities.first {
                selectedTab = activity.id.uuidString
            }
        }
    }
}

#Preview {
    ListActivityEventView()
}
