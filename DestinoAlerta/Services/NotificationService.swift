//
//  NotificationService.swift
//  DestinoAlerta
//

import Foundation
import UserNotifications

@MainActor
final class NotificationService: ObservableObject {
    @Published var isAuthorized: Bool = false
    @Published var authorizationError: Error?

    private let notificationCenter = UNUserNotificationCenter.current()

    static let alarmCategoryIdentifier = "ALARM_CATEGORY"
    static let dismissActionIdentifier = "DISMISS_ACTION"
    static let snoozeActionIdentifier = "SNOOZE_ACTION"

    init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    func requestPermission() async {
        do {
            // Note: .criticalAlert requires special Apple entitlement
            // Using standard options that work for all apps
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = granted
            if granted {
                setupNotificationCategories()
            }
        } catch {
            authorizationError = error
            isAuthorized = false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    private func setupNotificationCategories() {
        let dismissAction = UNNotificationAction(
            identifier: Self.dismissActionIdentifier,
            title: "Dispensar",
            options: [.destructive]
        )

        let snoozeAction = UNNotificationAction(
            identifier: Self.snoozeActionIdentifier,
            title: "Adiar 2 min",
            options: []
        )

        let alarmCategory = UNNotificationCategory(
            identifier: Self.alarmCategoryIdentifier,
            actions: [dismissAction, snoozeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([alarmCategory])
    }

    func sendAlarmNotification(for destination: Destination) async {
        let content = UNMutableNotificationContent()
        content.title = "Chegando!"
        content.body = destination.name.isEmpty
            ? "Você está chegando ao seu destino. Prepare-se para descer!"
            : "Você está chegando: \(destination.name)"
        content.sound = .default
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        // .timeSensitive breaks through Focus mode without requiring special entitlement
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: destination.id.uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }

    func sendSnoozeNotification(for destination: Destination, delaySeconds: TimeInterval = 120) async {
        let content = UNMutableNotificationContent()
        content.title = "Chegando!"
        content.body = destination.name.isEmpty
            ? "Lembrete: Você está perto do seu destino!"
            : "Lembrete: \(destination.name)"
        content.sound = .default
        content.categoryIdentifier = Self.alarmCategoryIdentifier
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: delaySeconds,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(destination.id.uuidString)-snooze",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send snooze notification: \(error)")
        }
    }

    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    func cancelNotification(for destination: Destination) {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [destination.id.uuidString, "\(destination.id.uuidString)-snooze"]
        )
        notificationCenter.removeDeliveredNotifications(
            withIdentifiers: [destination.id.uuidString]
        )
    }
}
