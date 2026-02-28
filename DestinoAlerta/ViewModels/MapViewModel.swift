//
//  MapViewModel.swift
//  DestinoAlerta
//

import Foundation
import SwiftUI
import MapKit
import Combine

@MainActor
final class MapViewModel: ObservableObject {
    // Map state
    @Published var cameraPosition: MapCameraPosition = .automatic
    @Published var selectedCoordinate: CLLocationCoordinate2D?
    @Published var selectedRadius: Double = 500

    // Search
    @Published var searchText: String = ""
    @Published var searchResults: [MKMapItem] = []
    @Published var isSearching: Bool = false

    // Available radius options (meters)
    let radiusOptions: [Double] = [300, 500, 750, 1000]

    private var searchTask: Task<Void, Never>?

    // Default to São Paulo city center
    static let defaultCoordinate = CLLocationCoordinate2D(
        latitude: -23.5505,
        longitude: -46.6333
    )

    init() {
        cameraPosition = .region(MKCoordinateRegion(
            center: Self.defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        ))
    }

    func centerOnUserLocation(_ location: CLLocation) {
        cameraPosition = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    func selectLocation(_ coordinate: CLLocationCoordinate2D) {
        selectedCoordinate = coordinate
        cameraPosition = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    func clearSelection() {
        selectedCoordinate = nil
        searchText = ""
        searchResults = []
    }

    func createDestination() -> Destination? {
        guard let coordinate = selectedCoordinate else { return nil }

        return Destination(
            name: searchText.isEmpty ? "" : searchText,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            radius: selectedRadius
        )
    }

    // MARK: - Search

    func search() {
        searchTask?.cancel()

        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        searchTask = Task {
            do {
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = searchText
                request.resultTypes = [.address, .pointOfInterest]

                // Bias search to Brazil
                request.region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: -14.235, longitude: -51.9253),
                    span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
                )

                let search = MKLocalSearch(request: request)
                let response = try await search.start()

                if !Task.isCancelled {
                    searchResults = response.mapItems
                    isSearching = false
                }
            } catch {
                if !Task.isCancelled {
                    searchResults = []
                    isSearching = false
                }
            }
        }
    }

    func selectSearchResult(_ mapItem: MKMapItem) {
        guard let location = mapItem.placemark.location else { return }

        searchText = mapItem.name ?? mapItem.placemark.title ?? ""
        selectedCoordinate = location.coordinate
        searchResults = []

        cameraPosition = .region(MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    func radiusLabel(for radius: Double) -> String {
        if radius >= 1000 {
            return String(format: "%.1f km", radius / 1000)
        } else {
            return "\(Int(radius)) m"
        }
    }
}
