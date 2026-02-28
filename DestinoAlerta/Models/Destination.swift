//
//  Destination.swift
//  DestinoAlerta
//

import Foundation
import CoreLocation

struct Destination: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var latitude: Double
    var longitude: Double
    var radius: Double // meters
    var isFavorite: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "",
        latitude: Double,
        longitude: Double,
        radius: Double = 500,
        isFavorite: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radius = radius
        self.isFavorite = isFavorite
        self.createdAt = createdAt
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var region: CLCircularRegion {
        let region = CLCircularRegion(
            center: coordinate,
            radius: radius,
            identifier: id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false
        return region
    }
}
