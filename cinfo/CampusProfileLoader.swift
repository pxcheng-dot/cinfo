//
//  CampusProfileLoader.swift
//  cinfo
//
//  Loads university_campus_profiles.json (city / region line + public / private).
//  Keys match universities.csv `name` exactly.
//

import Foundation

enum CampusProfileLoader {

    struct Profile: Codable {
        let location: String
        let ownership: String
    }

    static let profiles: [String: Profile] = {
        guard
            let url = Bundle.main.url(forResource: "university_campus_profiles",
                                      withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let dict = try? JSONDecoder().decode([String: Profile].self, from: data)
        else { return [:] }
        return dict
    }()

    static func profile(for name: String) -> Profile? {
        profiles[name]
    }
}
