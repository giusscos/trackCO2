//
//  OnboardingView.swift
//  trackCO2
//

import HealthKit
import HealthKitUI
import SwiftData
import SwiftUI

struct OnboardingView: View {
    private enum Step: Int, CaseIterable {
        case welcome, react, budget, firstLog, streak, paywall
    }

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("skippedHealthInOnboarding") private var skippedHealthInOnboarding = false

    @State private var step: Step = .welcome
    @State private var isMovingForward = true
    @State private var isHealthConnected = false

    /// Steps shown with progress dots; the paywall stands on its own.
    private var progressSteps: [Step] { Step.allCases.filter { $0 != .paywall } }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if step == .paywall {
                PaywallView(
                    onPurchaseComplete: finishOnboarding,
                    onClose: finishOnboarding
                )
                .transition(pageTransition)
            } else {
                VStack(spacing: 0) {
                    topBar
                    page
                        .id(step)
                        .transition(pageTransition)
                }
            }
        }
        .animation(.spring(duration: 0.45, bounce: 0.15), value: step)
    }

    private var pageTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: isMovingForward ? .trailing : .leading).combined(with: .opacity),
            removal: .move(edge: isMovingForward ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .foregroundStyle(.primary)
            .opacity(step == .welcome ? 0 : 1)
            .disabled(step == .welcome)
            .accessibilityLabel(Text("onboarding.back"))

            HStack(spacing: 6) {
                ForEach(progressSteps, id: \.self) { item in
                    Capsule()
                        .fill(item.rawValue <= step.rawValue ? Color.primary : Color.secondary.opacity(0.25))
                        .frame(height: 5)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: step)

            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var page: some View {
        switch step {
        case .welcome:
            OnboardingWelcomeStep(onNext: goForward)
        case .react:
            OnboardingReactStep(onNext: goForward)
        case .budget:
            OnboardingBudgetStep(onNext: goForward)
        case .firstLog:
            OnboardingFirstLogStep(onNext: goForward)
        case .streak:
            OnboardingStreakStep(isHealthConnected: $isHealthConnected, onNext: goForward)
        case .paywall:
            EmptyView()
        }
    }

    private func goForward() {
        guard let next = Step(rawValue: step.rawValue + 1) else { return }
        isMovingForward = true
        step = next
    }

    private func goBack() {
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
        isMovingForward = false
        step = previous
    }

    @MainActor
    private func finishOnboarding() {
        // Home asks for Health access on launch; respect a skip made here.
        skippedHealthInOnboarding = !isHealthConnected
        hasCompletedOnboarding = true
    }
}

// MARK: - Shared Layout

/// Claud with a speech bubble above, used at the top of every step.
private struct OnboardingClaud: View {
    let score: Double
    let message: String
    var scale: CGFloat = 1.3

    private var health: ClaudHealth { ClaudHealth(score: score) }

    var body: some View {
        VStack(spacing: 6) {
            SpeechBubble(text: message, tailDirection: .down)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 280)
                .id(message)
                .transition(.scale(scale: 0.85, anchor: .bottom).combined(with: .opacity))

            ClaudCloudView(
                color: health.cloudBodyColor,
                baseEyeOpenness: health.baseEyeOpenness,
                isHungry: false
            )
            .scaleEffect(scale)
            .frame(width: 120 * scale, height: 96 * scale)
        }
        .animation(.spring(duration: 0.4, bounce: 0.3), value: message)
        .animation(.easeInOut(duration: 0.6), value: score)
    }
}

private struct OnboardingStepLayout<Header: View, Content: View, Footer: View>: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header()
                        .padding(.top, 12)

                    VStack(spacing: 8) {
                        Text(title)
                            .font(.system(.title, design: .rounded, weight: .bold))
                        Text(message)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .multilineTextAlignment(.center)

                    content()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            }

            VStack(spacing: 6) {
                footer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }
}

private struct OnboardingPrimaryButton: View {
    let title: LocalizedStringKey
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor.opacity(isEnabled ? 1 : 0.3), in: Capsule())
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

private struct OnboardingSecondaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
        }
    }
}

/// A selectable row card in Claud's material style.
private struct OnboardingOptionCard<Trailing: View>: View {
    let emoji: String
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    @ViewBuilder let trailing: () -> Trailing
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(verbatim: emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.secondary.opacity(0.1), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: title)
                        .font(.headline)
                    if let subtitle {
                        Text(verbatim: subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                trailing()
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.primary : .clear, lineWidth: 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - 1. Welcome

private struct OnboardingWelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        OnboardingStepLayout(
            title: "Meet Claud!",
            message: "onboarding.welcome.body",
            header: {
                OnboardingClaud(
                    score: 0.85,
                    message: String(localized: "onboarding.welcome.bubble"),
                    scale: 1.6
                )
            },
            content: { EmptyView() },
            footer: {
                OnboardingPrimaryButton(title: "Get Started", action: onNext)
            }
        )
    }
}

// MARK: - 2. Claud reacts

private struct OnboardingReactStep: View {
    let onNext: () -> Void

    private enum Choice { case drive, walk }

    @State private var choice: Choice? = nil

    private var score: Double {
        switch choice {
        case .drive: return 0.12
        case .walk: return 0.95
        case nil: return 0.5
        }
    }

    private var bubble: String {
        switch choice {
        case .drive: return String(format: String(localized: "onboarding.react.bubble.drive"), 1.5.formatted())
        case .walk: return String(format: String(localized: "onboarding.react.bubble.walk"), 0.75.formatted())
        case nil: return String(localized: "onboarding.react.bubble.idle")
        }
    }

    var body: some View {
        OnboardingStepLayout(
            title: "onboarding.react.title",
            message: "onboarding.react.body",
            header: {
                OnboardingClaud(score: score, message: bubble)
            },
            content: {
                HStack(spacing: 12) {
                    choiceButton(.drive, emoji: "🚗", title: String(localized: "onboarding.react.drive"),
                                 detail: String(format: String(localized: "onboarding.log.emitted"), 1.5.formatted()), color: .orange)
                    choiceButton(.walk, emoji: "🚶", title: String(localized: "onboarding.react.walk"),
                                 detail: String(format: String(localized: "onboarding.log.saved"), 0.75.formatted()), color: .green)
                }
            },
            footer: {
                OnboardingPrimaryButton(title: "Next", isEnabled: choice != nil, action: onNext)
                Text("onboarding.react.hint")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .opacity(choice == nil ? 1 : 0)
            }
        )
        .sensoryFeedback(trigger: choice) { _, new in
            new == .walk ? .success : .warning
        }
    }

    private func choiceButton(_ value: Choice, emoji: String, title: String, detail: String, color: Color) -> some View {
        let isSelected = choice == value
        return Button {
            withAnimation(.spring(duration: 0.4, bounce: 0.3)) { choice = value }
        } label: {
            VStack(spacing: 6) {
                Text(verbatim: emoji)
                    .font(.system(size: 40))
                    .scaleEffect(isSelected ? 1.15 : 1)
                Text(verbatim: title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(verbatim: detail)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(isSelected ? color : .clear, lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 3. Weekly budget

private struct OnboardingBudgetStep: View {
    let onNext: () -> Void

    @AppStorage("weeklyBudgetKg") private var weeklyBudgetKg: Double = 115.0

    private struct Option: Identifiable {
        let emoji: String
        let titleKey: String.LocalizationValue
        let kg: Double
        var id: Double { kg }
    }

    private let options: [Option] = [
        Option(emoji: "🌱", titleKey: "onboarding.budget.ambitious", kg: 50),
        Option(emoji: "🌍", titleKey: "onboarding.budget.target", kg: 115),
        Option(emoji: "🏙️", titleKey: "onboarding.budget.average", kg: 180),
    ]

    var body: some View {
        OnboardingStepLayout(
            title: "onboarding.budget.title",
            message: "onboarding.budget.body",
            header: {
                OnboardingClaud(score: 0.75, message: String(localized: "onboarding.budget.bubble"), scale: 1.1)
            },
            content: {
                VStack(spacing: 10) {
                    ForEach(options) { option in
                        OnboardingOptionCard(
                            emoji: option.emoji,
                            title: String(localized: option.titleKey),
                            subtitle: String(format: String(localized: "onboarding.budget.perWeek"), Int(option.kg)),
                            isSelected: weeklyBudgetKg == option.kg,
                            trailing: {
                                if option.kg == 115 {
                                    Text("onboarding.budget.recommended")
                                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                                        .textCase(.uppercase)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Color.green, in: Capsule())
                                }
                            },
                            action: {
                                withAnimation(.spring(duration: 0.25)) { weeklyBudgetKg = option.kg }
                            }
                        )
                    }
                }
            },
            footer: {
                OnboardingPrimaryButton(title: "Next", action: onNext)
            }
        )
    }
}

// MARK: - 4. First activity

private struct OnboardingFirstLogStep: View {
    let onNext: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [Activity]

    private struct Quick: Identifiable {
        let type: ActivityEmissionType
        let quantity: Double
        let titleKey: String.LocalizationValue
        var id: ActivityEmissionType { type }
    }

    private let quicks: [Quick] = [
        Quick(type: .walking, quantity: 2, titleKey: "onboarding.log.walk"),
        Quick(type: .biking, quantity: 5, titleKey: "onboarding.log.bike"),
        Quick(type: .recycling, quantity: 1, titleKey: "onboarding.log.recycle"),
        Quick(type: .bus, quantity: 10, titleKey: "onboarding.log.bus"),
        Quick(type: .train, quantity: 20, titleKey: "onboarding.log.train"),
        Quick(type: .car, quantity: 10, titleKey: "onboarding.log.car"),
    ]

    @State private var selected: ActivityEmissionType? = nil
    @State private var loggedEmission: Double? = nil

    private func activity(for type: ActivityEmissionType) -> Activity? {
        activities.first { $0.type == type }
    }

    private func emission(for quick: Quick) -> Double {
        let factor = activity(for: quick.type)?.co2Emission
            ?? defaultActivities.first { $0.type == quick.type }?.co2Emission
            ?? 0
        return quick.quantity * factor
    }

    private func emissionText(_ value: Double) -> String {
        let amount = abs(value).formatted(.number.precision(.fractionLength(0...2)))
        return value < 0
            ? String(format: String(localized: "onboarding.log.saved"), amount)
            : String(format: String(localized: "onboarding.log.emitted"), amount)
    }

    private var score: Double {
        guard let loggedEmission else { return 0.6 }
        return loggedEmission < 0 ? 1 : 0.3
    }

    private var bubble: String {
        guard let loggedEmission else { return String(localized: "onboarding.log.bubble") }
        return loggedEmission < 0
            ? String(localized: "onboarding.log.bubble.green")
            : String(localized: "onboarding.log.bubble.emit")
    }

    var body: some View {
        OnboardingStepLayout(
            title: "onboarding.log.title",
            message: "onboarding.log.body",
            header: {
                OnboardingClaud(score: score, message: bubble, scale: 0.95)
            },
            content: {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(quicks) { quick in
                        quickCard(quick)
                    }
                }
                .allowsHitTesting(loggedEmission == nil)
            },
            footer: {
                if loggedEmission == nil {
                    OnboardingPrimaryButton(title: "onboarding.log.cta", isEnabled: selected != nil, action: logSelected)
                    OnboardingSecondaryButton(title: "Skip", action: onNext)
                } else {
                    OnboardingPrimaryButton(title: "Next", action: onNext)
                }
            }
        )
        .sensoryFeedback(.success, trigger: loggedEmission != nil)
    }

    private func quickCard(_ quick: Quick) -> some View {
        let isSelected = selected == quick.type
        let value = emission(for: quick)
        return Button {
            withAnimation(.spring(duration: 0.25)) { selected = quick.type }
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Text(verbatim: quick.type.emoji)
                        .font(.title3)
                    Text(verbatim: String(localized: quick.titleKey))
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2, reservesSpace: true)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(verbatim: emissionText(value))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(value < 0 ? Color.green : Color.orange)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.primary : .clear, lineWidth: 1.5)
            }
            .opacity(loggedEmission != nil && !isSelected ? 0.4 : 1)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    private func logSelected() {
        guard let type = selected, let quick = quicks.first(where: { $0.type == type }) else { return }
        let target: Activity
        if let existing = activity(for: type) {
            target = existing
        } else if let template = defaultActivities.first(where: { $0.type == type }) {
            target = Activity(
                type: template.type,
                name: template.type.defaultNameKey,
                activityDescription: template.activityDescription,
                quantityUnit: template.quantityUnit,
                emissionUnit: template.emissionUnit,
                co2Emission: template.co2Emission
            )
            modelContext.insert(target)
        } else {
            return
        }
        modelContext.insert(ActivityEvent(quantity: quick.quantity, activity: target))
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            loggedEmission = quick.quantity * target.co2Emission
        }
    }
}

// MARK: - 5. Streak, reminder and Apple Health

private struct OnboardingStreakStep: View {
    @Binding var isHealthConnected: Bool
    let onNext: () -> Void

    @State private var notificationManager = NotificationManager.shared
    @State private var healthTrigger = false

    private let healthStore = HKHealthStore()
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType(.stepCount),
        HKQuantityType(.distanceWalkingRunning)
    ]

    var body: some View {
        OnboardingStepLayout(
            title: "onboarding.streak.title",
            message: "onboarding.streak.body",
            header: {
                OnboardingClaud(score: 0.9, message: String(localized: "onboarding.streak.bubble"), scale: 1.1)
            },
            content: {
                VStack(spacing: 10) {
                    permissionCard(
                        emoji: "🔔",
                        title: String(localized: "onboarding.streak.reminder.title"),
                        subtitle: String(localized: "onboarding.streak.reminder.body"),
                        isOn: notificationManager.isAuthorized
                    ) {
                        Task { await notificationManager.requestAuthorization() }
                    }

                    if HKHealthStore.isHealthDataAvailable() {
                        permissionCard(
                            emoji: "❤️",
                            title: String(localized: "onboarding.health.title"),
                            subtitle: String(localized: "onboarding.health.body"),
                            isOn: isHealthConnected
                        ) {
                            healthTrigger.toggle()
                        }
                    }
                }
            },
            footer: {
                OnboardingPrimaryButton(title: "Next", action: onNext)
            }
        )
        .healthDataAccessRequest(store: healthStore, readTypes: readTypes, trigger: healthTrigger) { result in
            Task { @MainActor in
                if case .success = result { isHealthConnected = true }
            }
        }
        .task { await notificationManager.checkAuthorization() }
    }

    private func permissionCard(emoji: String, title: String, subtitle: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        OnboardingOptionCard(
            emoji: emoji,
            title: title,
            subtitle: subtitle,
            isSelected: isOn,
            trailing: {
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("onboarding.permission.turnOn")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(.systemBackground))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.accentColor, in: Capsule())
                }
            },
            action: {
                guard !isOn else { return }
                action()
            }
        )
        .animation(.spring(duration: 0.35), value: isOn)
    }
}

#Preview {
    OnboardingView()
        .environment(Store())
        .modelContainer(for: [Activity.self, ActivityEvent.self], inMemory: true)
}
