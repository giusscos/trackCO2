//
//  TipsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import SwiftUI

struct TipsView: View {
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text("Tips")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                NavigationLink {
                    
                } label: {
                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
            .font(.headline)
            
            Text("Try to reduce the amount of meat 🥩")
                .fontWeight(.bold)
                .lineLimit(3)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))    }
}

#Preview {
    TipsView()
}
