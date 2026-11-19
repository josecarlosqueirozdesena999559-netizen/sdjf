import Foundation
import SwiftUI

struct ProfilePhoto: Identifiable, Hashable, Codable {
    let id: UUID
    var imageData: Data?
    var remoteURL: String?
    /// Used for rich local demo profiles when no network image is loaded.
    var placeholderPaletteHexes: [String]?
    var placeholderSymbol: String?
    var placeholderCaption: String?

    init(
        id: UUID = UUID(),
        imageData: Data? = nil,
        remoteURL: String? = nil,
        placeholderPaletteHexes: [String]? = nil,
        placeholderSymbol: String? = nil,
        placeholderCaption: String? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.remoteURL = remoteURL
        self.placeholderPaletteHexes = placeholderPaletteHexes
        self.placeholderSymbol = placeholderSymbol
        self.placeholderCaption = placeholderCaption
    }
}

struct LegalAcceptance: Codable, Hashable {
    let termsVersion: String
    let acceptedAt: Date
}

struct PermissionPreferences: Codable, Hashable {
    var locationAuthorized: Bool = false
    var notificationsAuthorized: Bool = false
    var locationUpdatedAt: Date?
    var notificationsUpdatedAt: Date?
}

struct UserProfile: Identifiable, Hashable, Codable {
    let id: UUID
    var fullName: String
    var email: String
    var username: String
    var birthDate: Date
    var age: Int
    var photos: [ProfilePhoto]
    var interests: [Interest]
    var lookingFor: [String]
    var bio: String
    var isVerified: Bool
    var isOnline: Bool
    var lastActiveAt: Date?
    var distanceKm: Int
    var city: String
    var legalAcceptance: LegalAcceptance?
    var permissions: PermissionPreferences

    init(
        id: UUID = UUID(),
        fullName: String,
        email: String = "",
        username: String,
        birthDate: Date = Date(),
        age: Int,
        photos: [ProfilePhoto],
        interests: [Interest],
        lookingFor: [String] = ["todos"],
        bio: String,
        isVerified: Bool = false,
        isOnline: Bool = false,
        lastActiveAt: Date? = nil,
        distanceKm: Int = 2,
        city: String = "São Paulo",
        legalAcceptance: LegalAcceptance? = nil,
        permissions: PermissionPreferences = PermissionPreferences()
    ) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.username = username
        self.birthDate = birthDate
        self.age = age
        self.photos = photos
        self.interests = interests
        self.lookingFor = lookingFor
        self.bio = bio
        self.isVerified = isVerified
        self.isOnline = isOnline
        self.lastActiveAt = lastActiveAt
        self.distanceKm = distanceKm
        self.city = city
        self.legalAcceptance = legalAcceptance
        self.permissions = permissions
    }

    var firstName: String {
        fullName.split(separator: " ").first.map(String.init) ?? fullName
    }
}

struct DiscoveryFilter: Hashable, Codable {
    var maxDistanceKm: Double = 30
    var minAge: Int = 18
    var maxAge: Int = 45
    var lookingFor: [String] = ["todos"]
    var onlyVerified: Bool = false
    var onlyOnline: Bool = false
}
