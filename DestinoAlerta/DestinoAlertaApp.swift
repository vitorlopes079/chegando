//
//  DestinoAlertaApp.swift
//  DestinoAlerta
//
//  Created by vitor lopes on 26/02/2026.
//

import SwiftUI
import UserNotifications

@main
struct DestinoAlertaApp: App {
    @StateObject private var locationService = LocationService()
    @StateObject private var geofenceService = GeofenceService()
    @StateObject private var notificationService = NotificationService()

    init() {
        // Configure notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(locationService)
                .environmentObject(geofenceService)
                .environmentObject(notificationService)
                .onAppear {
                    setupGeofenceCallback()
                }
        }
    }

    private func setupGeofenceCallback() {
        geofenceService.onRegionEntered = { [notificationService] destination in
            Task {
                await notificationService.sendAlarmNotification(for: destination)
            }
        }
    }
}

// MARK: - Notification Delegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    private override init() {
        super.init()
    }

    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    // Handle notification action (dismiss/snooze buttons)
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier

        switch actionIdentifier {
        case NotificationService.dismissActionIdentifier:
            // User tapped dismiss - handled by the app
            break
        case NotificationService.snoozeActionIdentifier:
            // User tapped snooze - schedule another notification
            break
        default:
            break
        }

        completionHandler()
    }
}
