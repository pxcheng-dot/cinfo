//
//  CampusHeroImage.swift
//  cinfo
//
//  Bundled campus photos (top SRS schools) in CampusHero/*.jpg; filenames match
//  `slug(for:)` of the CSV `name` field. Keep in sync with scripts/fetch_campus_hero_images.py.
//

import UIKit

enum CampusHeroImage {

    private static let cache = NSCache<NSString, UIImage>()

    /// Bundle name stem for `{slug}.jpg` (often at bundle root next to `universities.csv`, or under `CampusHero/`).
    static func slug(for collegeName: String) -> String {
        var s = collegeName
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
        while s.contains("__") {
            s = s.replacingOccurrences(of: "__", with: "_")
        }
        return s.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    static func uiImage(for collegeName: String) -> UIImage? {
        let stem = slug(for: collegeName)
        let key = stem as NSString
        if let hit = cache.object(forKey: key) { return hit }

        let bundle = Bundle.main
        // Synced `cinfo` sources often copy JPGs flat next to `universities.csv`; some builds keep `CampusHero/`.
        let url =
            bundle.url(forResource: stem, withExtension: "jpg", subdirectory: "CampusHero")
            ?? bundle.url(forResource: stem, withExtension: "jpg")
            ?? bundle.url(forResource: stem, withExtension: "jpg", subdirectory: "cinfo/CampusHero")

        guard let url, let image = UIImage(contentsOfFile: url.path) else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}
