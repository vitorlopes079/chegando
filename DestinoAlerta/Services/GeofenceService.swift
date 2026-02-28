//
//  GeofenceService.swift
//  DestinoAlerta
//

import Foundation
import CoreLocation

@MainActor
final class GeofenceService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var activeDestination: Destination?
    @Published var didEnterRegion: Bool = false
    @Published var monitoringError: Error?

    var onRegionEntered: ((Destination) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func startMonitoring(destination: Destination) {
        stopMonitoringAll()

        let region = destination.region
        locationManager.startMonitoring(for: region)
        activeDestination = destination
        didEnterRegion = false
    }

    func stopMonitoring(destination: Destination) {
        let region = destination.region
        locationManager.stopMonitoring(for: region)
        if activeDestination?.id == destination.id {
            activeDestination = nil
        }
    }

    func stopMonitoringAll() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        activeDestination = nil
        didEnterRegion = false
    }

    var isMonitoring: Bool {
        activeDestination != nil
    }

    var monitoredRegionsCount: Int {
        locationManager.monitoredRegions.count
    }
}

extension GeofenceService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        Task { @MainActor in
            if let destination = self.activeDestination,
               destination.id.uuidString == circularRegion.identifier {
                self.didEnterRegion = true
                self.onRegionEntered?(destination)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        // Not used in v1 - we only care about entering
    }

    nonisolated func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task { @MainActor in
            self.monitoringError = error
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        // Monitoring started successfully
        manager.requestState(for: region)
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        // Check if user is already inside the region when monitoring starts
        if state == .inside {
            Task { @MainActor in
                if let destination = self.activeDestination,
                   destination.id.uuidString == region.identifier {
                    self.didEnterRegion = true
                    self.onRegionEntered?(destination)
                }
            }
        }
    }
}
