//
//  NotificationManager.swift
//  trackCO2
//

import Foundation
import UserNotifications

@Observable
class NotificationManager {
    static let shared = NotificationManager()

    private(set) var isAuthorized = false

    init() {
        Task { await checkAuthorization() }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run { isAuthorized = granted }
            if granted { scheduleDailyReminder() }
        } catch {}
    }

    /// Schedules (or reschedules) a daily reminder at the given hour (24-hour, default 20:00).
    func scheduleDailyReminder(hour: Int = 20) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["co2.daily-reminder"])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Log Your Activities")
        content.body = String(localized: "Don't forget to record today's CO₂ activities! 🌍")
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "co2.daily-reminder", content: content, trigger: trigger)
        center.add(request)
    }

    /// Fires a one-shot milestone notification (deduped by milestone value).
    func sendMilestoneNotification(offsetKg: Double) {
        let id = "co2.milestone-\(Int(offsetKg))"
        UNUserNotificationCenter.current().getPendingNotificationRequests { pending in
            guard !pending.contains(where: { $0.identifier == id }) else { return }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Milestone Reached! 🎉")
            content.body = String(localized: "You've offset \(String(format: "%.0f", offsetKg)) kg CO₂ total! Keep it up! 🌱")
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    func cancelReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        isAuthorized = false
    }
}
