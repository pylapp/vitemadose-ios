//
//  VaccinationCentre.swift
//  ViteMaDose
//
//  Created by Victor Sarda on 07/04/2021.
//

import Foundation
import MapKit
import PhoneNumberKit
import SwiftDate

// MARK: - VaccinationCentre

struct VaccinationCentre: Codable, Equatable {
    let departement: String?
    let nom: String?
    let url: String?
    let location: Location?
    let metadata: Metadata?
    let prochainRdv: String?
    let plateforme: String?
    let type: String?
    let appointmentCount: Int?
    let vaccineType: [String]?

    enum CodingKeys: String, CodingKey {
        case departement = "departement"
        case nom = "nom"
        case url = "url"
        case location = "location"
        case metadata = "metadata"
        case prochainRdv = "prochain_rdv"
        case plateforme = "plateforme"
        case type = "type"
        case appointmentCount = "appointment_count"
        case vaccineType = "vaccine_type"
    }
}

extension VaccinationCentre {
    struct Location: Codable, Equatable {
        let longitude: Double?
        let latitude: Double?
        let city: String?

        enum CodingKeys: String, CodingKey {
            case longitude
            case latitude
            case city
        }
    }

    struct Metadata: Codable, Equatable {
        let address: String?
        let phoneNumber: String?
        let businessHours: [String: String?]?

        enum CodingKeys: String, CodingKey {
            case address
            case phoneNumber = "phone_number"
            case businessHours = "business_hours"
        }
    }
}

extension VaccinationCentre {
    var isAvailable: Bool {
        return prochainRdv != nil
    }

    var nextAppointmentDay: String? {
        return prochainRdv?.toString(with: .date(.long), region: AppConstant.franceRegion)
    }

    var nextAppointmentTime: String? {
        return prochainRdv?.toString(with: .time(.short), region: AppConstant.franceRegion)
    }

    var appointmentUrl: URL? {
        guard
            let urlString = self.url,
            let url = URL(string: urlString),
            url.isValid
        else {
            return nil
        }
        return URL(string: urlString)
    }

    var phoneUrl: URL? {
        guard
            let phoneNumber = metadata?.phoneNumber,
            let phoneNumberUrl = URL(string: "tel://\(phoneNumber)"),
            phoneNumberUrl.isValid
        else {
            return nil
        }
        return phoneNumberUrl
    }

    var locationAsCLLocation: CLLocation? {
        guard
            let latitude = location?.latitude,
            let longitude = location?.longitude
        else {
            return nil
        }
        return CLLocation(
            latitude: latitude,
            longitude: longitude
        )
    }

    func formattedCentreName(selectedLocation: CLLocation?) -> String {
        guard var name = nom else {
            return Localization.Location.unavailable_name
        }

        if
            let location = locationAsCLLocation,
            let selectedLocation = selectedLocation
        {
            // Add distance in kilometres
            let distanceInKm = location.distance(from: selectedLocation) / 1000
            let formattedDistance = String(format: "%.1f", distanceInKm)
            name.append(String.space + "(\(formattedDistance) km)")
        }

        return name
    }

    func formattedPhoneNumber(_ phoneNumberKit: PhoneNumberKit) -> String? {
        guard let metaDataPhoneNumber = metadata?.phoneNumber else { return nil }
        let parsedPhoneNumber = try? phoneNumberKit.parse(
            metaDataPhoneNumber,
            withRegion: "FR",
            ignoreType: true
        )
        guard let phoneNumber = parsedPhoneNumber else { return nil }
        return phoneNumberKit.format(phoneNumber, toType: .national)
    }
}

// MARK: - VaccinationCentres

struct VaccinationCentres: Codable, Equatable {
    let lastUpdated: String?
    let centresDisponibles: [VaccinationCentre]
    let centresIndisponibles: [VaccinationCentre]

    enum CodingKeys: String, CodingKey {
        case lastUpdated = "last_updated"
        case centresDisponibles = "centres_disponibles"
        case centresIndisponibles = "centres_indisponibles"
    }
}

typealias LocationVaccinationCentres = [VaccinationCentres]
