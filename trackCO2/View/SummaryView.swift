//
//  SummaryView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import SwiftData
import SwiftUI
import HealthKit
import StoreKit

struct SummaryView: View {
    enum ActiveSheet: Identifiable {
        case createActivityEvent
        case createActivity
        case selectActivities
        case selectAppIcon
        case customizeHomeOrder

        var id: String {
            switch self {
            case .createActivityEvent: return "createActivityEvent"
            case .createActivity:      return "createActivity"
            case .selectActivities:    return "selectActivities"
            case .selectAppIcon:       return "selectAppIcon"
            case .customizeHomeOrder:  return "customizeHomeOrder"
            }
        }
    }

    private static let widgetColumns = [
        GridItem(.flexible(minimum: 0), spacing: 8),
        GridItem(.flexible(minimum: 0), spacing: 8)
    ]

    @AppStorage("appIcon") var appIcon: String = defaultAppIcon
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("homeSectionOrder") private var homeSectionOrderRaw: String = HomeSection.defaultOrderRaw

    @Environment(\.modelContext) var modelContext
    @Environment(\.requestReview) var requestReview

    @Query var activities: [Activity]

    @State private var healthKitManager = HealthKitManager.shared
    @State private var notificationManager = NotificationManager.shared

    @State var activeSheet: ActiveSheet?

    @State private var manageSubscription: Bool = false

    @Environment(Store.self) private var storeKit

    @State private var showAddYesterdayWalkingAlert = false
    @State private var yesterdayDistance: Double = 0.0
    @State private var healthKitAuthorized: Bool = false
    @State private var reviewCheckTask: Task<Void, Never>?

    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    #if DEBUG
    @State private var showEraseAllDataConfirmation = false
    #endif

    private var sectionOrder: [HomeSection] {
        HomeSection.resolvedOrder(from: homeSectionOrderRaw)
    }

    var body: some View {
        NavigationStack {
            summaryScrollContent
                .navigationTitle("Summary")
                .toolbar { summaryToolbar() }
                .sheet(item: $activeSheet, content: sheetContent)
                .sheet(isPresented: $showShareSheet) { shareSheet }
                .manageSubscriptionsSheet(isPresented: $manageSubscription, subscriptionGroupID: storeKit.groupId)
                .onAppear(perform: handleAppear)
                .onChange(of: hasCompletedOnboarding, handleOnboardingChange)
                .onChange(of: showAddYesterdayWalkingAlert, handleWalkingAlertChange)
                .onChange(of: activeSheet, handleActiveSheetChange)
                .onDisappear { reviewCheckTask?.cancel() }
                .modifier(SummaryDebugDialogModifier(
                    showEraseAllDataConfirmation: debugEraseBinding,
                    onErase: eraseAllDataIfDebug
                ))
                .alert(
                    "Add yesterday's walking distance?",
                    isPresented: $showAddYesterdayWalkingAlert,
                    actions: walkingAlertActions,
                    message: walkingAlertMessage
                )
        }
    }

    // MARK: - Subviews

    private var summaryScrollContent: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(sectionOrder) { section in
                    sectionView(section)
                }
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func sectionView(_ section: HomeSection) -> some View {
        switch section {
        case .mascot:
            ClaudMascotView(healthScore: calculateWeeklyCO2Health(activities: activities))
        case .co2Chart:
            CO2ChartView()
        case .weather:
            WeatherSuggestionView()
        case .healthKit:
            if healthKitAuthorized {
                pairedWidgets {
                    StepCountView()
                    WalkingRunningDistanceView()
                }
            }
        case .balance:
            pairedWidgets {
                CompensationView()
                ConsumptionView()
            }
        case .budgetStreak:
            pairedWidgets {
                BudgetView()
                StreakView()
            }
        case .insights:
            pairedWidgets {
                MostUsedView()
                TipsView()
            }
        case .trends:
            if hasAnyTrendsData(activities: activities) {
                TrendsView()
            }
        case .calendar:
            NavigationLink {
                CalendarHeatmapView()
            } label: {
                CalendarHeatmapPreviewRow(activities: activities)
            }
            .buttonStyle(.plain)
        }
    }

    private func pairedWidgets<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LazyVGrid(columns: Self.widgetColumns, alignment: .leading, spacing: 8) {
            content()
        }
        .frame(minWidth: 0, maxWidth: .infinity)
    }

    @ToolbarContentBuilder
    private func summaryToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                activeSheet = .createActivityEvent
            } label: {
                if #available(iOS 26, *) {
                    Label("Add", systemImage: "plus")
                } else {
                    Label("Add", systemImage: "plus.circle.fill")
                }
            }
            .disabled(activities.isEmpty)
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                moreMenuContent
            } label: {
                if #available(iOS 26, *) {
                    Label("More", systemImage: "ellipsis")
                } else {
                    Label("More", systemImage: "ellipsis.circle.fill")
                }
            }
        }
    }

    @ViewBuilder
    private var moreMenuContent: some View {
        Button {
            activeSheet = .createActivity
        } label: {
            Label("Add activity", systemImage: "plus")
        }

        Button {
            activeSheet = .selectActivities
        } label: {
            Label("Add default activities", systemImage: "square.and.arrow.down.on.square")
        }

        Divider()

        Button {
            generateAndShare()
        } label: {
            Label("Share my stats", systemImage: "square.and.arrow.up")
        }
        .disabled(activities.isEmpty)

        Button {
            activeSheet = .customizeHomeOrder
        } label: {
            Label("Customize Home", systemImage: "arrow.up.arrow.down")
        }

        Divider()

        Button {
            activeSheet = .selectAppIcon
        } label: {
            Label("App Icon", systemImage: "inset.filled.square.dashed")
        }

        Divider()

        if notificationManager.isAuthorized {
            Button(role: .destructive) {
                notificationManager.cancelReminders()
            } label: {
                Label("Turn off reminders", systemImage: "bell.slash")
            }
        } else {
            Button {
                Task { await notificationManager.requestAuthorization() }
            } label: {
                Label("Enable daily reminder", systemImage: "bell.badge")
            }
        }

        Divider()

        if storeKit.purchasedSubscriptions.count > 0 {
            Button {
                manageSubscription.toggle()
            } label: {
                Text("Manage subscription")
            }
        }

        #if DEBUG
        Divider()

        Button {
            generateMockData()
        } label: {
            Label("Generate mock data", systemImage: "wand.and.stars")
        }

        Button(role: .destructive) {
            showEraseAllDataConfirmation = true
        } label: {
            Label("Erase all data", systemImage: "trash")
        }
        #endif

        Divider()

        Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
        Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ActiveSheet) -> some View {
        switch sheet {
        case .createActivityEvent:
            ListActivityEventView()
        case .createActivity:
            CreateActivityView()
        case .selectActivities:
            SelectActivitiesToPersistView()
        case .selectAppIcon:
            SelectAppIconView(selectedIcon: $appIcon)
        case .customizeHomeOrder:
            CustomizeHomeOrderView(orderRaw: $homeSectionOrderRaw)
        }
    }

    @ViewBuilder
    private var shareSheet: some View {
        if let img = shareImage {
            ShareSheet(items: [img])
                .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private func walkingAlertActions() -> some View {
        Button("Add", role: .none, action: addYesterdayWalking)
        Button("Cancel", role: .cancel) {}
    }

    private func walkingAlertMessage() -> Text {
        Text("You walked \(String(format: "%.2f", yesterdayDistance / 1000.0)) km yesterday. Would you like to record this as an activity event?")
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        guard hasCompletedOnboarding else { return }
        loadHealthKitData()
        scheduleReviewRequestIfAppropriate()
        checkMilestones()
    }

    private func handleOnboardingChange(_: Bool, completed: Bool) {
        guard completed else { return }
        loadHealthKitData()
        scheduleReviewRequestIfAppropriate()
    }

    private func handleWalkingAlertChange(wasShowing: Bool, isShowing: Bool) {
        guard wasShowing, !isShowing else { return }
        scheduleReviewRequestIfAppropriate()
    }

    private func handleActiveSheetChange(_: ActiveSheet?, sheet: ActiveSheet?) {
        guard sheet == nil else { return }
        scheduleReviewRequestIfAppropriate()
    }

    // MARK: - Actions

    @MainActor
    private func generateAndShare() {
        let card = ShareCardView(activities: activities)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale
        guard let uiImage = renderer.uiImage else { return }
        shareImage = uiImage
        showShareSheet = true
    }

    private func checkMilestones() {
        guard notificationManager.isAuthorized else { return }
        let compensation = calculateCO2Totals(activities: activities).compensation
        let milestones: [Double] = [10, 50, 100, 250, 500, 1000]
        for milestone in milestones where compensation >= milestone {
            notificationManager.sendMilestoneNotification(offsetKg: milestone)
        }
    }

    private func addYesterdayWalking() {
        let walkingActivity = activities.first { $0.type == .walking }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
              let walkingActivity else { return }
        let event = ActivityEvent(quantity: yesterdayDistance / 1000.0, activity: walkingActivity)
        event.createdAt = yesterday
        modelContext.insert(event)
    }

    private func loadHealthKitData() {
        healthKitManager.requestAuthorization { success in
            healthKitAuthorized = success
            if success {
                healthKitManager.fetchTodayData()
                healthKitManager.fetchHistoryData()
                healthKitManager.fetchStepsPerHourForToday()
                healthKitManager.fetchDistancePerHourForToday()
                healthKitManager.fetchYesterdayDistance { distance in
                    guard distance > 0 else { return }
                    let walkingActivity = activities.first { $0.type == .walking }
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
                    let hasEvent = walkingActivity?.events?.contains(where: { event in
                        calendar.isDate(event.createdAt, inSameDayAs: yesterday)
                    }) ?? false
                    if !hasEvent {
                        yesterdayDistance = distance
                        showAddYesterdayWalkingAlert = true
                    }
                }
            }
        }
    }

    #if DEBUG
    private var debugEraseBinding: Binding<Bool> {
        $showEraseAllDataConfirmation
    }

    private func eraseAllDataIfDebug() {
        eraseAllData()
    }

    private func generateMockData() {
        do {
            try DevelopmentDataManager.generateMockData(in: modelContext)
        } catch {
            print("Failed to generate mock data: \(error.localizedDescription)")
        }
    }

    private func eraseAllData() {
        do {
            try DevelopmentDataManager.eraseAllData(in: modelContext)
        } catch {
            print("Failed to erase data: \(error.localizedDescription)")
        }
    }
    #else
    private var debugEraseBinding: Binding<Bool> {
        .constant(false)
    }

    private func eraseAllDataIfDebug() {}
    #endif

    private func scheduleReviewRequestIfAppropriate() {
        reviewCheckTask?.cancel()
        reviewCheckTask = Task { @MainActor in
            AppReviewManager.recordVisit()
            try? await Task.sleep(for: .seconds(AppReviewManager.promptDelay))
            guard !Task.isCancelled else { return }
            guard activeSheet == nil, !showAddYesterdayWalkingAlert else { return }
            guard AppReviewManager.shouldRequestReview(activities: activities) else { return }
            requestReview()
            AppReviewManager.markReviewRequested()
        }
    }
}

// MARK: - Debug Dialog

private struct SummaryDebugDialogModifier: ViewModifier {
    @Binding var showEraseAllDataConfirmation: Bool
    let onErase: () -> Void

    func body(content: Content) -> some View {
        #if DEBUG
        content
            .confirmationDialog(
                "Erase all data?",
                isPresented: $showEraseAllDataConfirmation,
                titleVisibility: .visible
            ) {
                Button("Erase all data", role: .destructive, action: onErase)
            } message: {
                Text("This permanently deletes all activities, events, and favorite places.")
            }
        #else
        content
        #endif
    }
}

// MARK: - Calendar Preview Row

private struct CalendarHeatmapPreviewRow: View {
    let activities: [Activity]

    private let calendar = Calendar.current

    private var last14Days: [Date] {
        (0..<14).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }.reversed()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
                Text("Activity Calendar")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Label("Navigate to", systemImage: "chevron.right")
                    .labelStyle(.iconOnly)
                    .font(.headline)
            }

            HStack(spacing: 4) {
                ForEach(last14Days, id: \.self) { date in
                    let net = calculateDailyNetCO2(activities: activities, for: date)
                    let style = CO2DayStyle.style(for: net)
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(style.color)
                        if let glyph = style.glyph, net != nil {
                            Text(glyph)
                                .font(.system(size: 10))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 30)
                    .overlay {
                        if calendar.isDateInToday(date) {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.accentColor, lineWidth: 2)
                        }
                    }
                    .accessibilityLabel(style.accessibilityLabel)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    SummaryView()
        .environment(Store())
}
