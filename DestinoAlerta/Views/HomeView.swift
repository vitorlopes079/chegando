//
//  HomeView.swift
//  DestinoAlerta
//

import SwiftUI
import CoreLocation

struct HomeView: View {
    @EnvironmentObject var locationService: LocationService
    @EnvironmentObject var geofenceService: GeofenceService
    @EnvironmentObject var notificationService: NotificationService

    @StateObject private var soundService = AlarmSoundService.shared

    @State private var showMapPicker = false
    @State private var showAlarm = false
    @State private var showLiveTracking = false
    @State private var showLocationPermissionAlert = false
    @State private var currentDistance: Double = 0
    @State private var pendingDestination: Destination?

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Logo area with radar animation
                    ZStack {
                        // Radar animation (only when monitoring)
                        if geofenceService.isMonitoring {
                            RadarPulseView()
                        }

                        // App icon
                        Image(systemName: "location.fill")
                            .font(.system(size: 50, weight: .medium))
                            .foregroundStyle(Theme.accent)
                            .glow(Theme.accent, radius: 10)
                    }
                    .frame(height: 200)

                    // App name
                    Text(Theme.appName)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.top, 8)

                    // Tagline
                    Text(Theme.tagline)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 4)

                    Spacer()

                    // Active alarm card with live distance
                    if let destination = geofenceService.activeDestination {
                        liveTrackingCard(destination: destination)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                            .onTapGesture {
                                showLiveTracking = true
                            }
                    }

                    // Main action button
                    Button {
                        showMapPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: geofenceService.isMonitoring ? "mappin.and.ellipse" : "plus.circle.fill")
                                .font(.title2)

                            Text(geofenceService.isMonitoring ? "Alterar Destino" : "Definir Destino")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Theme.accent)
                        .foregroundStyle(Theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .glow(Theme.accent, radius: 8)
                    }
                    .padding(.horizontal, 24)

                    // Cancel button
                    if geofenceService.isMonitoring {
                        Button {
                            cancelAlarm()
                        } label: {
                            Text("Cancelar Alarme")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Theme.alarm)
                        }
                        .padding(.top, 16)
                    }

                    // Permission warnings (only for denied location and notifications)
                    VStack(spacing: 8) {
                        if locationService.isDenied {
                            permissionWarning(
                                icon: "location.slash.fill",
                                message: "Permissão de localização negada"
                            )
                        }

                        if !notificationService.isAuthorized {
                            permissionWarning(
                                icon: "bell.slash.fill",
                                message: "Ative as notificações para o alarme"
                            )
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if geofenceService.isMonitoring {
                        Button {
                            soundService.toggleRain()
                        } label: {
                            Image(systemName: soundService.isRainPlaying ? "cloud.rain.fill" : "cloud.rain")
                                .font(.title3)
                                .foregroundStyle(soundService.isRainPlaying ? Theme.accent : Theme.textTertiary)
                                .symbolEffect(.bounce, value: soundService.isRainPlaying)
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showMapPicker) {
                MapPickerView { destination in
                    handleDestinationSelected(destination)
                }
            }
            .fullScreenCover(isPresented: $showLiveTracking) {
                if let destination = geofenceService.activeDestination {
                    LiveTrackingView(destination: destination)
                }
            }
            .fullScreenCover(isPresented: $showAlarm) {
                if let destination = geofenceService.activeDestination {
                    AlarmView(destination: destination) {
                        dismissAlarm()
                    } onSnooze: {
                        snoozeAlarm()
                    }
                }
            }
            .alert("Permissão Necessária", isPresented: $showLocationPermissionAlert) {
                Button("Abrir Ajustes") {
                    openSettings()
                }
                Button("Cancelar", role: .cancel) {
                    pendingDestination = nil
                }
            } message: {
                Text("Para o alarme funcionar com a tela bloqueada, você precisa permitir o acesso à localização como 'Sempre'. Toque em Ajustes para corrigir.")
            }
            .onChange(of: geofenceService.didEnterRegion) { _, entered in
                if entered {
                    triggerAlarm()
                }
            }
            .onChange(of: locationService.currentLocation) { _, newLocation in
                updateDistance(newLocation)
            }
            .onChange(of: locationService.authorizationStatus) { _, newStatus in
                // Check if permission was granted after returning from Settings
                if newStatus == .authorizedAlways, let destination = pendingDestination {
                    activateAlarm(for: destination)
                    pendingDestination = nil
                }
            }
            .onAppear {
                // Start location updates when monitoring to show distance
                if geofenceService.isMonitoring {
                    locationService.startUpdatingLocation()
                    updateDistance(locationService.currentLocation)
                    // Resume rain if it was enabled
                    soundService.startRainIfEnabled()
                }
            }
            .task {
                await notificationService.checkAuthorizationStatus()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Live Tracking Card

    @ViewBuilder
    private func liveTrackingCard(destination: Destination) -> some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 8, height: 8)
                    .glow(Theme.accent, radius: 3)

                Text("ALARME ATIVO")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(Theme.accent)
                    .tracking(1.5)

                Spacer()

                // Distance badge
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                    Text(formattedDistance)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isNearDestination ? Theme.alarm.opacity(0.2) : Theme.accent.opacity(0.2))
                .foregroundStyle(isNearDestination ? Theme.alarm : Theme.accent)
                .clipShape(Capsule())
            }

            // Destination info
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(Theme.accent)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(destination.name.isEmpty ? "Destino definido" : destination.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)

                    Text("Você está a \(formattedDistance) do destino")
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                // Arrow to indicate it's tappable
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }

            // Tap hint
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                Text("Toque para ver no mapa")
                    .font(.caption2)
            }
            .foregroundStyle(Theme.textTertiary)
        }
        .padding(16)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Distance Helpers

    private var formattedDistance: String {
        if currentDistance <= 0 {
            return "..."
        } else if currentDistance >= 1000 {
            return String(format: "%.1f km", currentDistance / 1000)
        } else {
            return "\(Int(currentDistance)) m"
        }
    }

    private var isNearDestination: Bool {
        currentDistance > 0 && currentDistance < 500
    }

    private func updateDistance(_ location: CLLocation?) {
        guard let location = location,
              let destination = geofenceService.activeDestination else {
            return
        }

        let destLocation = CLLocation(
            latitude: destination.latitude,
            longitude: destination.longitude
        )

        currentDistance = location.distance(from: destLocation)
    }

    // MARK: - Permission Warning

    @ViewBuilder
    private func permissionWarning(icon: String, message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Theme.alarm)
                .font(.caption)

            Text(message)
                .font(.caption)
                .foregroundStyle(Theme.textTertiary)

            Spacer()

            Button("Ajustes") {
                openSettings()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(Theme.accent)
        }
        .padding(12)
        .background(Theme.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Actions

    private func handleDestinationSelected(_ destination: Destination) {
        // Check location permission status
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            // Permission granted - activate alarm
            activateAlarm(for: destination)

        case .notDetermined:
            // First time - request permission, save destination for later
            pendingDestination = destination
            locationService.requestAlwaysPermission()

        case .authorizedWhenInUse, .denied, .restricted:
            // Need to go to Settings - iOS won't show prompt again
            pendingDestination = destination
            showLocationPermissionAlert = true

        @unknown default:
            pendingDestination = destination
            showLocationPermissionAlert = true
        }
    }

    private func activateAlarm(for destination: Destination) {
        // Request notification permission if needed
        Task {
            if !notificationService.isAuthorized {
                await notificationService.requestPermission()
            }
        }

        geofenceService.startMonitoring(destination: destination)

        // Start location updates for distance tracking
        locationService.startUpdatingLocation()

        // Start rain sound if user has it enabled
        soundService.startRainIfEnabled()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    private func cancelAlarm() {
        // Stop all sounds (rain and alarm)
        soundService.stopAll()

        geofenceService.stopMonitoringAll()
        notificationService.cancelAllNotifications()
        locationService.stopUpdatingLocation()
        currentDistance = 0
    }

    private func triggerAlarm() {
        guard let destination = geofenceService.activeDestination else { return }

        // Stop rain and start alarm sound (handled by soundService.startAlarm)
        // Note: AlarmView will call soundService.startAlarm() on appear

        Task {
            await notificationService.sendAlarmNotification(for: destination)
        }

        showAlarm = true
    }

    private func dismissAlarm() {
        showAlarm = false

        // Stop all sounds - do NOT resume rain after alarm
        soundService.stopAll()

        geofenceService.stopMonitoringAll()
        notificationService.cancelAllNotifications()
        locationService.stopUpdatingLocation()
        currentDistance = 0
    }

    private func snoozeAlarm() {
        showAlarm = false

        // Stop alarm sound but do NOT resume rain
        soundService.stopAlarm()

        guard let destination = geofenceService.activeDestination else { return }

        Task {
            await notificationService.sendSnoozeNotification(for: destination)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(LocationService())
        .environmentObject(GeofenceService())
        .environmentObject(NotificationService())
}
