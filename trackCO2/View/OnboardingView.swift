//
//  OnboardingView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 18/07/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var selection = 0
    let onFinish: () -> Void
    
    var body: some View {
        TabView(selection: $selection) {
            VStack(spacing: 32) {
                Image("paywall-world")
                    .resizable()
                    .frame(minWidth: 150, maxWidth: 350, minHeight: 150, maxHeight: 350)
                    .aspectRatio(1/1, contentMode: .fit)
                
                VStack {
                    Text("Welcome to trackCO2!")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Track your carbon footprint by logging your daily activities. Discover how your choices impact the environment and make a difference!")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .tag(0)
            
            VStack(spacing: 32) {
                Image("paywall-tree")
                    .resizable()
                    .frame(minWidth: 150, maxWidth: 350, minHeight: 150, maxHeight: 350)
                    .aspectRatio(1/1, contentMode: .fit)
                
                VStack {
                    Text("See Your Impact")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Visualize your progress, set goals, and get tips to reduce your emissions. Start your journey to a greener lifestyle today!")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Button {
                    onFinish()
                } label: {
                    Text("Get started".capitalized)
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
            .tag(1)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .interactiveDismissDisabled()
    }
}

#Preview {
    OnboardingView(onFinish: {})
} 
