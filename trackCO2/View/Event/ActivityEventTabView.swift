//
//  ActivityEventTabView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftUI

struct ActivityEventTabView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
    var activity: Activity
    
    var currentCO2Emission: Double = 0.00
    
    var isHorizontal: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text(activity.type.emoji)
                    .font(.largeTitle)
                
                Text(activity.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
            }
                        
            Group {
                if isHorizontal {
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Reference")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack (alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(activity.co2Emission, specifier: "%.2f")")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("\(activity.emissionUnit.rawValue)/\(activity.quantityUnit.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Image(systemName: "arrow.left")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Actual")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack (alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(currentCO2Emission, specifier: "%.2f")")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .contentTransition(.numericText(value: currentCO2Emission))
                                
                                Text("\(activity.emissionUnit.rawValue)/\(activity.quantityUnit.rawValue)")
                                    .font(.caption)
                            }
                            .foregroundStyle(currentCO2Emission > 0 ? .red : currentCO2Emission == 0 ? .blue : .green)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Reference")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack (alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(activity.co2Emission, specifier: "%.2f")")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("\(activity.emissionUnit.rawValue)/\(activity.quantityUnit.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Image(systemName: "arrow.up")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Actual")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack (alignment: .lastTextBaseline, spacing: 2) {
                                Text("\(currentCO2Emission, specifier: "%.2f")")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .contentTransition(.numericText(value: currentCO2Emission))
                                
                                Text("\(activity.emissionUnit.rawValue)/\(activity.quantityUnit.rawValue)")
                                    .font(.caption)
                            }
                            .foregroundStyle(currentCO2Emission > 0 ? .red : currentCO2Emission == 0 ? .blue : .green)
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: isHorizontal ? 400 : 300, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ActivityEventTabView(
        activity: Activity(name: "Car", co2Emission: 0.15)
    )
}
