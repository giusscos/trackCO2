//
//  ClaudMascotView.swift
//  trackCO2
//

import SwiftUI

// MARK: - Mascot Type

enum MascotType: String, CaseIterable, Identifiable {
    case claud, tri, ert
    var id: Self { self }
    var name: String {
        switch self {
        case .claud: return "Claud"
        case .tri:   return "Tri"
        case .ert:   return "Ert"
        }
    }
    static func from(appIcon: String) -> MascotType {
        switch appIcon {
        case "world": return .ert
        case "tree":  return .tri
        default:      return .claud
        }
    }
}

// MARK: - Health Model

struct ClaudHealth {
    let score: Double

    var label: String {
        switch score {
        case 0.75...: return String(localized: "Thriving")
        case 0.5..<0.75: return String(localized: "Good")
        case 0.25..<0.5: return String(localized: "Neutral")
        case 0.1..<0.25: return String(localized: "Tired")
        default: return String(localized: "Sick")
        }
    }

    var message: String {
        switch score {
        case 0.75...: return String(localized: "I feel amazing!\nKeep saving the planet! 🌱")
        case 0.5..<0.75: return String(localized: "I'm doing well!\nNice CO₂ tracking this week!")
        case 0.25..<0.5: return String(localized: "I'm okay…\nTry to offset a bit more?")
        case 0.1..<0.25: return String(localized: "Feeling tired…\nMore green choices, please!")
        default: return String(localized: "I'm not well…\nToo much CO₂ this week!")
        }
    }

    var hungryMessage: String {
        switch score {
        case 0.5...: return String(localized: "Hey, I'm peckish!\nGive me a green snack! 🌿")
        case 0.25...: return String(localized: "My tummy's rumbling!\nMore compensation, please! 🍃")
        default: return String(localized: "I'M STARVING!\nWay too much CO₂! 😰")
        }
    }

    func weatherMessage(for suggestion: WeatherManager.WalkingSuggestion) -> String {
        switch suggestion {
        case .walk: return String(localized: "Sky is clear!\nPerfect day to walk. 🌤️")
        case .caution: return String(localized: "A bit cloudy…\nA short walk still counts! 🚶")
        case .avoid: return String(localized: "Stay safe!\nPoor air today. 🏠")
        case .unknown: return message
        }
    }

    var tintColor: Color {
        switch score {
        case 0.75...: return .green
        case 0.5..<0.75: return .mint
        case 0.25..<0.5: return .yellow
        case 0.1..<0.25: return .orange
        default: return .red
        }
    }

    var cloudBodyColor: Color { Color(white: 0.30 + score * 0.68) }

    var baseEyeOpenness: CGFloat {
        switch score {
        case 0.5...: return 1.00
        case 0.25..<0.5: return 0.82
        case 0.1..<0.25: return 0.62
        default: return 0.46
        }
    }
}

// MARK: - Life Bar

struct LifeBar: View {
    let score: Double

    private var barColor: Color {
        score >= 0.6 ? .green : score >= 0.3 ? .yellow : .red
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: max(4, geo.size.width * score))
                        .animation(.spring(duration: 0.6), value: score)
                }
            }
            .frame(height: 8)

            Text("\(Int(score * 100))% health")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Shared Eye

private struct EyeView: View {
    let eyeOpenness: CGFloat
    let isHungry: Bool
    let pupilOffset: CGSize
    let outerD: CGFloat
    let innerD: CGFloat
    let pupilD: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(.black).frame(width: outerD)
            Circle().fill(.white).frame(width: innerD)
            Circle().fill(.black).frame(width: pupilD).offset(pupilOffset)
        }
        .scaleEffect(y: isHungry ? 1.5 : eyeOpenness, anchor: .center)
    }
}

// MARK: - Claud (Cloud)

struct ClaudCloudView: View {
    let color: Color
    let baseEyeOpenness: CGFloat
    let isHungry: Bool

    @State private var breathScale: CGFloat = 1.0
    @State private var eyeOpenness: CGFloat = 1.0
    @State private var pupilOffset: CGSize = .zero

    private let cw: CGFloat = 120
    private let ch: CGFloat = 96

    var body: some View {
        ZStack {
            ZStack {
                cloudPrimitives(.black)
                cloudPrimitives(color).scaleEffect(0.92)
                    .animation(.easeInOut(duration: 0.8), value: color)
            }
            .drawingGroup()

            HStack(spacing: 14) {
                EyeView(eyeOpenness: eyeOpenness, isHungry: isHungry,
                        pupilOffset: pupilOffset, outerD: 23, innerD: 19, pupilD: 9)
                EyeView(eyeOpenness: eyeOpenness, isHungry: isHungry,
                        pupilOffset: pupilOffset, outerD: 23, innerD: 19, pupilD: 9)
            }
            .offset(x: 2, y: 14)
        }
        .frame(width: cw, height: ch)
        .scaleEffect(breathScale)
        .onAppear { eyeOpenness = baseEyeOpenness }
        .onChange(of: baseEyeOpenness) { _, v in withAnimation(.easeInOut(duration: 0.6)) { eyeOpenness = v } }
        .task { startBreathing() }
        .task { await blinkLoop() }
        .task { await lookLoop() }
    }

    @ViewBuilder
    private func cloudPrimitives(_ c: Color) -> some View {
        ZStack {
            Circle().frame(width: 68, height: 68).offset(x: -20, y: -14)
            Circle().frame(width: 52, height: 52).offset(x: 22,  y: -6)
            Capsule().frame(width: 108, height: 52).offset(y: 15)
        }
        .foregroundStyle(c).frame(width: cw, height: ch)
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) { breathScale = 1.045 }
    }
    private func blinkLoop() async {
        do { while true {
            try await Task.sleep(for: .seconds(Double.random(in: 2.5...5.0)))
            guard !isHungry else { continue }
            withAnimation(.easeInOut(duration: 0.07)) { eyeOpenness = 0.05 }
            try await Task.sleep(for: .seconds(0.13))
            withAnimation(.easeInOut(duration: 0.09)) { eyeOpenness = baseEyeOpenness }
        }} catch { }
    }
    private func lookLoop() async {
        do { while true {
            try await Task.sleep(for: .seconds(Double.random(in: 1.8...3.8)))
            let m: CGFloat = 3.5
            withAnimation(.easeInOut(duration: 0.35)) {
                pupilOffset = CGSize(width: CGFloat.random(in: -m...m),
                                     height: CGFloat.random(in: -m...m))
            }
        }} catch { }
    }
}

// MARK: - Tri (Tree)

struct TriTreeView: View {
    let baseEyeOpenness: CGFloat
    let isHungry: Bool

    @State private var breathScale: CGFloat = 1.0
    @State private var eyeOpenness: CGFloat = 1.0
    @State private var pupilOffset: CGSize = .zero

    private let cw: CGFloat = 104
    private let ch: CGFloat = 118

    private let canopyColor = Color(red: 0.25, green: 0.44, blue: 0.18)
    private let trunkColor  = Color(red: 0.50, green: 0.24, blue: 0.07)

    var body: some View {
        ZStack {
            ZStack {
                RoundedRectangle(cornerRadius: 7).fill(.black)
                    .frame(width: 28, height: 46).offset(y: 34)
                RoundedRectangle(cornerRadius: 6).fill(trunkColor)
                    .frame(width: 22, height: 42).offset(y: 35)
            }

            ZStack {
                canopyPrimitives(.black)
                canopyPrimitives(canopyColor).scaleEffect(0.91)
            }
            .drawingGroup()

            HStack(spacing: 14) {
                EyeView(eyeOpenness: eyeOpenness, isHungry: isHungry,
                        pupilOffset: pupilOffset, outerD: 21, innerD: 17, pupilD: 8)
                EyeView(eyeOpenness: eyeOpenness, isHungry: isHungry,
                        pupilOffset: pupilOffset, outerD: 21, innerD: 17, pupilD: 8)
            }
            .offset(x: 1, y: 2)
        }
        .frame(width: cw, height: ch)
        .scaleEffect(breathScale)
        .onAppear { eyeOpenness = baseEyeOpenness }
        .onChange(of: baseEyeOpenness) { _, v in withAnimation(.easeInOut(duration: 0.6)) { eyeOpenness = v } }
        .task { startBreathing() }
        .task { await blinkLoop() }
        .task { await lookLoop() }
    }

    @ViewBuilder
    private func canopyPrimitives(_ c: Color) -> some View {
        ZStack {
            Circle().frame(width: 46).offset(x:  0,  y: -28)
            Circle().frame(width: 40).offset(x: -26, y: -16)
            Circle().frame(width: 40).offset(x:  26, y: -16)
            Circle().frame(width: 44).offset(x: -24, y:  4)
            Circle().frame(width: 44).offset(x:  24, y:  4)
            Circle().frame(width: 42).offset(x:   0, y: -6)
        }
        .foregroundStyle(c).frame(width: cw, height: ch)
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) { breathScale = 1.04 }
    }
    private func blinkLoop() async {
        do { while true {
            try await Task.sleep(for: .seconds(Double.random(in: 2.5...5.0)))
            guard !isHungry else { continue }
            withAnimation(.easeInOut(duration: 0.07)) { eyeOpenness = 0.05 }
            try await Task.sleep(for: .seconds(0.13))
            withAnimation(.easeInOut(duration: 0.09)) { eyeOpenness = baseEyeOpenness }
        }} catch { }
    }
    private func lookLoop() async {
        do { while true {
            try await Task.sleep(for: .seconds(Double.random(in: 1.8...3.8)))
            let m: CGFloat = 3.0
            withAnimation(.easeInOut(duration: 0.35)) {
                pupilOffset = CGSize(width: CGFloat.random(in: -m...m),
                                     height: CGFloat.random(in: -m...m))
            }
        }} catch { }
    }
}

// MARK: - Ert (Earth)

struct ErtEarthView: View {
    let baseEyeOpenness: CGFloat
    let isHungry: Bool

    @State private var breathScale: CGFloat = 1.0
    @State private var eyeOpenness: CGFloat = 1.0
    @State private var pupilOffset: CGSize = .zero

    private let globeD: CGFloat = 100
    private let oceanColor     = Color(red: 0.20, green: 0.52, blue: 0.78)
    private let continentColor = Color(red: 0.24, green: 0.42, blue: 0.18)

    var body: some View {
        ZStack {
            Circle().fill(.black).frame(width: globeD + 8)
            ZStack {
                Circle().fill(oceanColor)
                ZStack {
                    continentBlobs(.black).scaleEffect(1.11)
                    continentBlobs(continentColor)
                }
                .drawingGroup()
            }
            .frame(width: globeD, height: globeD)
            .clipShape(Circle())

            HStack(spacing: 14) {
                EyeView(eyeOpenness: eyeOpenness, isHungry: isHungry,
                        pupilOffset: pupilOffset, outerD: 22, innerD: 18, pupilD: 8)
                EyeView(eyeOpenness: eyeOpenness, isHungry: isHungry,
                        pupilOffset: pupilOffset, outerD: 22, innerD: 18, pupilD: 8)
            }
            .offset(x: -4, y: 4)
        }
        .frame(width: globeD + 8, height: globeD + 8)
        .scaleEffect(breathScale)
        .onAppear { eyeOpenness = baseEyeOpenness }
        .onChange(of: baseEyeOpenness) { _, v in withAnimation(.easeInOut(duration: 0.6)) { eyeOpenness = v } }
        .task { startBreathing() }
        .task { await blinkLoop() }
        .task { await lookLoop() }
    }

    @ViewBuilder
    private func continentBlobs(_ c: Color) -> some View {
        ZStack {
            Ellipse().frame(width: 36, height: 44).offset(x: -4,  y:  4)
            Ellipse().frame(width: 26, height: 18).offset(x: -6,  y: -24)
            Ellipse().frame(width: 28, height: 16).offset(x:  20, y: -18)
            Ellipse().frame(width: 16, height: 16).offset(x:  14, y:  -6)
            Ellipse().frame(width: 22, height: 26).offset(x: -30, y: -8)
            Ellipse().frame(width: 16, height: 22).offset(x: -26, y:  18)
            Ellipse().frame(width: 18, height: 14).offset(x:  32, y:  22)
            Ellipse().frame(width: 14, height: 10).offset(x: -16, y: -34)
            Ellipse().frame(width: 28, height: 8).offset(x:  -2,  y:  38)
        }
        .foregroundStyle(c)
        .frame(width: globeD, height: globeD)
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) { breathScale = 1.04 }
    }
    private func blinkLoop() async {
        do { while true {
            try await Task.sleep(for: .seconds(Double.random(in: 2.5...5.0)))
            guard !isHungry else { continue }
            withAnimation(.easeInOut(duration: 0.07)) { eyeOpenness = 0.05 }
            try await Task.sleep(for: .seconds(0.13))
            withAnimation(.easeInOut(duration: 0.09)) { eyeOpenness = baseEyeOpenness }
        }} catch { }
    }
    private func lookLoop() async {
        do { while true {
            try await Task.sleep(for: .seconds(Double.random(in: 1.8...3.8)))
            let m: CGFloat = 3.5
            withAnimation(.easeInOut(duration: 0.35)) {
                pupilOffset = CGSize(width: CGFloat.random(in: -m...m),
                                     height: CGFloat.random(in: -m...m))
            }
        }} catch { }
    }
}

// MARK: - Speech Bubble shapes

struct SpeechBubbleDownShape: Shape {
    var tailFraction: CGFloat = 0.45   // tail tip x as fraction of width
    var cornerRadius: CGFloat = 18
    var tailH: CGFloat = 20
    var tailW: CGFloat = 26

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let bodyBottom = rect.maxY - tailH
        let tx = rect.width * tailFraction

        var p = Path()
        // Top edge
        p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        // Top-right arc
        p.addArc(center: .init(x: rect.maxX - r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        // Right edge
        p.addLine(to: CGPoint(x: rect.maxX, y: bodyBottom - r))
        // Bottom-right arc
        p.addArc(center: .init(x: rect.maxX - r, y: bodyBottom - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        // Bottom edge → tail right base
        p.addLine(to: CGPoint(x: tx + tailW / 2, y: bodyBottom))
        // Tail tip
        p.addLine(to: CGPoint(x: tx, y: rect.maxY))
        // Tail left base → bottom edge
        p.addLine(to: CGPoint(x: tx - tailW / 2, y: bodyBottom))
        p.addLine(to: CGPoint(x: rect.minX + r, y: bodyBottom))
        // Bottom-left arc
        p.addArc(center: .init(x: rect.minX + r, y: bodyBottom - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        // Left edge
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        // Top-left arc
        p.addArc(center: .init(x: rect.minX + r, y: rect.minY + r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.closeSubpath()
        return p
    }
}

struct SpeechBubbleUpShape: Shape {
    var tailFraction: CGFloat = 0.5
    var cornerRadius: CGFloat = 18
    var tailH: CGFloat = 20
    var tailW: CGFloat = 26

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let bodyTop = rect.minY + tailH
        let tx = rect.width * tailFraction

        var p = Path()
        p.move(to: CGPoint(x: tx - tailW / 2, y: bodyTop))
        p.addLine(to: CGPoint(x: tx, y: rect.minY))
        p.addLine(to: CGPoint(x: tx + tailW / 2, y: bodyTop))
        p.addLine(to: CGPoint(x: rect.maxX - r, y: bodyTop))
        p.addArc(center: .init(x: rect.maxX - r, y: bodyTop + r),
                 radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: .init(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: .init(x: rect.minX + r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX, y: bodyTop + r))
        p.addArc(center: .init(x: rect.minX + r, y: bodyTop + r),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: tx - tailW / 2, y: bodyTop))
        p.closeSubpath()
        return p
    }
}

enum SpeechBubbleTailDirection {
    case up, down

    var shape: AnyShape {
        switch self {
        case .up: AnyShape(SpeechBubbleUpShape())
        case .down: AnyShape(SpeechBubbleDownShape())
        }
    }
}

struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path { pathBuilder(rect) }
}

struct SpeechBubble: View {
    let text: String
    var tailDirection: SpeechBubbleTailDirection = .down

    var body: some View {
        Text(text)
            .font(.callout).fontWeight(.medium)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.top, tailDirection == .up ? 32 : 14)
            .padding(.bottom, tailDirection == .up ? 14 : 32)
            .modifier(SpeechBubbleBackground(tailDirection: tailDirection))
    }
}

private struct SpeechBubbleBackground: ViewModifier {
    let tailDirection: SpeechBubbleTailDirection

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(.regular, in: tailDirection.shape)
        } else {
            content
                .background {
                    ZStack {
                        tailDirection.shape
                            .fill(.ultraThinMaterial)
                        tailDirection.shape
                            .stroke(Color.primary.opacity(0.25), lineWidth: 1.5)
                    }
                }
        }
    }
}

// MARK: - Mascot Widget

struct ClaudMascotView: View {
    let healthScore: Double

    @AppStorage("appIcon") private var appIcon: String = "claud"

    @State private var weather = WeatherManager.shared
    @State private var showBubble: Bool = false
    @State private var isHungry: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var tapCount: Int = 0
    @State private var lastTapDate: Date = .distantPast
    @State private var bubbleScheduleStarted = false

    private var health: ClaudHealth { ClaudHealth(score: healthScore) }
    private var activeMascot: MascotType { .from(appIcon: appIcon) }

    var body: some View {
        VStack(spacing: 0) {
            mascotDrawing
                .offset(x: shakeOffset)
                .contentShape(Rectangle())
                .onTapGesture { handleTap() }
                .padding(.top, 8)
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                Text(activeMascot.name)
                    .font(.title3).fontWeight(.bold)

                Text(health.label)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(health.tintColor)
                    .padding(.horizontal, 12).padding(.vertical, 5)
                    .background(health.tintColor.opacity(0.15))
                    .clipShape(Capsule())

                LifeBar(score: healthScore)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .overlay(alignment: .top) {
                if showBubble {
                    SpeechBubble(
                        text: isHungry ? health.hungryMessage : health.weatherMessage(for: weather.suggestion),
                        tailDirection: .up
                    )
                    .fixedSize(horizontal: true, vertical: false)
                    .alignmentGuide(.top) { dimensions in dimensions[.bottom] }
                    .allowsHitTesting(false)
                    .transition(
                        .scale(scale: 0.85, anchor: .top)
                        .combined(with: .opacity)
                    )
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.1), value: showBubble)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .task(id: bubbleScheduleStarted) {
            guard bubbleScheduleStarted else { return }
            await runBubbleSchedule()
        }
        .onAppear {
            if !bubbleScheduleStarted { bubbleScheduleStarted = true }
        }
    }

    private func runBubbleSchedule() async {
        do {
            try await Task.sleep(for: .seconds(Double.random(in: 4.0...10.0)))
            while !Task.isCancelled {
                guard !isHungry else {
                    try await Task.sleep(for: .seconds(1))
                    continue
                }
                withAnimation { showBubble = true }
                try await Task.sleep(for: .seconds(Double.random(in: 3.0...5.0)))
                guard !isHungry else { continue }
                withAnimation { showBubble = false }
                try await Task.sleep(for: .seconds(Double.random(in: 8.0...18.0)))
            }
        } catch { }
    }

    @ViewBuilder
    private var mascotDrawing: some View {
        switch activeMascot {
        case .claud:
            ClaudCloudView(color: health.cloudBodyColor,
                           baseEyeOpenness: health.baseEyeOpenness,
                           isHungry: isHungry)
        case .tri:
            TriTreeView(baseEyeOpenness: health.baseEyeOpenness,
                        isHungry: isHungry)
        case .ert:
            ErtEarthView(baseEyeOpenness: health.baseEyeOpenness,
                         isHungry: isHungry)
        }
    }

    // MARK: Tap logic (5 rapid taps = hungry easter egg)

    private func handleTap() {
        let now = Date()
        tapCount = now.timeIntervalSince(lastTapDate) < 1.8 ? tapCount + 1 : 1
        lastTapDate = now

        if tapCount >= 5 {
            tapCount = 0
            triggerHungry()
        }
        // Normal taps do nothing — bubble appears on its own schedule
    }

    private func triggerHungry() {
        isHungry = true
        showBubble = true
        shake()
        Task {
            do {
                try await Task.sleep(for: .seconds(3.8))
                withAnimation { isHungry = false; showBubble = false }
            } catch { }
        }
    }

    private func shake() {
        let offsets: [CGFloat] = [9, -9, 7, -7, 5, -5, 3, -3, 0]
        for (i, offset) in offsets.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.07) {
                withAnimation(.easeInOut(duration: 0.06)) { shakeOffset = offset }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ClaudMascotView(healthScore: 0.9)
            ClaudMascotView(healthScore: 0.5)
            ClaudMascotView(healthScore: 0.05)
        }
        .padding()
    }
}
