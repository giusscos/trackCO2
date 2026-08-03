//
//  CustomizeHomeOrderView.swift
//  trackCO2
//

import SwiftUI

struct CustomizeHomeOrderView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var orderRaw: String

    @State private var order: [HomeSection] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(order) { section in
                        Label(section.title, systemImage: section.systemImage)
                    }
                    .onMove(perform: move)
                } footer: {
                    Text("Drag to change the order of sections on the Home screen.")
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Customize Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") {
                        withAnimation {
                            order = HomeSection.defaultOrder
                            orderRaw = HomeSection.defaultOrderRaw
                        }
                    }
                    .disabled(order == HomeSection.defaultOrder)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        orderRaw = HomeSection.encode(order)
                        dismiss()
                    }
                }
            }
            .onAppear {
                order = HomeSection.resolvedOrder(from: orderRaw)
            }
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        order.move(fromOffsets: source, toOffset: destination)
        orderRaw = HomeSection.encode(order)
    }
}

#Preview {
    CustomizeHomeOrderView(orderRaw: .constant(HomeSection.defaultOrderRaw))
}
