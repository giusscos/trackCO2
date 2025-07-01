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
    
    @State var co2EmissionsToAdd: Double = 0.0
    
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
            
            TabView {
                ForEach(activities) { activity in
                    VStack {
                        ActivityEventTabView(activity: activity)
                        
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
                            
                            HStack (alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(co2EmissionsToAdd, specifier: "%.1f")")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .contentTransition(.numericText(value: co2EmissionsToAdd))
                                
                                Text("\(activity.type.quantityUnit)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
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
                    }
                    .padding()
                }
                
                ForEach(ActivityType.allCases) { activityType in
                    let emoji = activityType.emoji
                    
                    if let predefined = predefinedActivities[activityType] {
                        VStack {
                            DefaultActivityEventTabView(predefined: predefined, emoji: emoji)
                        }
                    }
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

#Preview {
    ListActivityEventView()
}
