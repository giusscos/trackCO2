//
//  TipsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import SwiftData
import SwiftUI

struct TipsView: View {
    @Query var activities: [Activity]

    private var tips: [GeneratedTip] {
        TipGenerator.generate(from: activities)
    }

    private var topTip: GeneratedTip? {
        tips.first
    }

    var body: some View {
        VStack (alignment: .leading) {
            NavigationLink {
                ListTipsView()
            } label: {
                HStack {
                    Text("Tips")
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
            .font(.headline)

            if let tip = topTip {
                Text(tip.message)
                    .fontWeight(.bold)
                    .lineLimit(2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TipsView()
}
