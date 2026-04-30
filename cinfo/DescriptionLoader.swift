//
//  DescriptionLoader.swift
//  cinfo
//
//  Loads the university_descriptions.json bundle resource once at startup
//  and vends descriptions by university name.
//

import Foundation

enum DescriptionLoader {

    /// Full descriptions keyed by the exact university name as it appears in the CSV.
    static let descriptions: [String: String] = {
        guard
            let url  = Bundle.main.url(forResource: "university_descriptions",
                                       withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let dict = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return dict
    }()

    static func description(for name: String) -> String? {
        descriptions[name]
    }
}
