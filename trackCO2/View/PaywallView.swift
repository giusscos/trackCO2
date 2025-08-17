//
//  PaywallView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    enum ActiveSheet: Identifiable {
        case lifetimePlan
        
        var id: String {
            switch self {
                case .lifetimePlan:
                    return "lifetimePlan"
            }
        }
    }
    @Environment(\.colorScheme) var colorScheme
    
    @State var storeKit = Store()
    
    @State var activeSheet: ActiveSheet?
    
    private let contentData = [
        (
            title: "Welcome to trackCO2!",
            description: "Track your carbon footprint by logging your daily activities. Discover how your choices impact the environment and make a difference!",
            imageName: "paywall-world"
        ),
        (
            title: "Track your carbon footprint.",
            description: "Add your personal activities and see how much CO2 you're saving every day.",
            imageName: "paywall-tree"
        ),
        (
            title: "See Your Impact.",
            description: "Visualize your progress, set goals, and get tips to reduce your emissions. Start your journey to a greener lifestyle today!",
            imageName: "paywall-claud"
        )
    ]
    
    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: storeKit.groupId) {
                VStack {
                    Button {
                        activeSheet = .lifetimePlan
                    } label: {
                        Label("Save with Lifetime plans", systemImage: "sparkle")
                            .font(.headline)
                    }
                    .tint(.purple)
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    
                    TabView() {
                        ForEach(0..<contentData.count, id: \.self) { index in
                            VStack {
                                Group {
                                    if contentData[index].imageName == "paywall-claud" {
                                        Image("\(contentData[index].imageName)\(colorScheme == .dark ? "-dark" : "-light")")
                                            .resizable()
                                    } else {
                                        Image(contentData[index].imageName)
                                            .resizable()
                                    }
                                }
                                .scaledToFit()
                                
                                Text(contentData[index].title)
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                                
                                Text(contentData[index].description)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .tag(index)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .padding(.vertical)
                    
                    HStack {
                        Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                            .foregroundColor(.primary)
                            .buttonStyle(.plain)
                        
                        Text("and")
                            .foregroundStyle(.secondary)
                        
                        Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                            .foregroundColor(.primary)
                            .buttonStyle(.plain)
                    }
                    .font(.caption)
                    .padding(8)
                }
                .frame(minHeight: 300)
            }
            .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
            .subscriptionStoreButtonLabel(.multiline)
            .storeButton(.visible, for: .restorePurchases)
            .storeButton(.hidden, for: .cancellation)
            .tint(.primary)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                    case .lifetimePlan:
                        PaywallLifetimeView()
                            .presentationDetents(.init([.medium]))
                }
            }
        }
    }
}

#Preview {
    PaywallView()
}
