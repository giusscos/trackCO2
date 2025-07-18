//
//  SelectAppIconView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 18/07/25.
//

import SwiftUI

struct AppIconOption: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    let iconName: String? // nil for default
    let displayName: String
}

struct SelectAppIconView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedIcon: String

    let appIconOptions: [AppIconOption] = [
        AppIconOption(imageName: "claud", iconName: nil, displayName: "Claud"),
        AppIconOption(imageName: "world", iconName: "AppIconWorld", displayName: "World"),
        AppIconOption(imageName: "tree", iconName: "AppIconTree", displayName: "Tree")
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(appIconOptions) { option in
                    HStack {
                        Image(option.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        Text(option.displayName)
                            .font(.headline)
                        
                        if selectedIcon == option.imageName {
                            Image(systemName: "checkmark")
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    .onTapGesture {
                        selectedIcon = option.imageName
                        
                        UIApplication.shared.setAlternateIconName(option.iconName)
                    }
                }
            }
            .navigationTitle("Select Icon")
        }
    }
}

#Preview {
    SelectAppIconView(selectedIcon: .constant("claud"))
}
