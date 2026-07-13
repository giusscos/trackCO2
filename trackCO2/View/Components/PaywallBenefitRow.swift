//
//  PaywallBenefitRow.swift
//  trackCO2
//

import SwiftUI

struct GlassLifetimeButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
        }
    }
}

struct PaywallBenefitRow: View {
    let icon: String
    let accent: Color
    let text: LocalizedStringKey
    let index: Int

    @State private var appeared = false
    @State private var iconBounce = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.gradient.opacity(0.22))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accent.gradient)
                    .symbolEffect(.bounce, value: iconBounce)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent.opacity(0.09))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(accent.opacity(0.18), lineWidth: 1)
                }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -28)
        .scaleEffect(appeared ? 1 : 0.94, anchor: .leading)
        .onAppear {
            let delay = 0.18 + Double(index) * 0.11
            withAnimation(.spring(duration: 0.58, bounce: 0.34).delay(delay)) {
                appeared = true
            }
            Task {
                try? await Task.sleep(for: .seconds(delay + 0.22))
                iconBounce.toggle()
            }
        }
    }
}
