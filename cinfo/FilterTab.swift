//
//  FilterTab.swift
//  cinfo
//
//  Defines the country/region filter tabs shown at the top of the list.
//  "Europe" groups continental European countries; "Other" covers Japan and South Korea.
//  Hong Kong universities appear under the China tab (while keeping the 🇭🇰 flag on their cards).
//  The tab order (excluding "All") is stored in UserDefaults so users can personalise it.
//

import Foundation

// Each case is one tab in the horizontal filter bar.
enum FilterTab: String, CaseIterable, Identifiable {
    case all        = "all"
    case us         = "us"
    case uk         = "uk"
    case europe     = "europe"
    case australia  = "australia"
    case canada     = "canada"
    case singapore  = "singapore"
    case china      = "china"
    case other      = "other"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all:       return "All"
        case .us:        return "🇺🇸 US"
        case .uk:        return "🇬🇧 UK"
        case .europe:    return "🇪🇺 Europe"
        case .australia: return "🇦🇺 Australia"
        case .canada:    return "🇨🇦 Canada"
        case .singapore: return "🇸🇬 Singapore"
        case .china:     return "🇨🇳 China"
        case .other:     return "🌏 Other"
        }
    }

    func localizedLabel(lang: String) -> String {
        switch self {
        case .all:       return l("filter_all",       lang)
        case .us:        return "🇺🇸 US"
        case .uk:        return "🇬🇧 UK"
        case .europe:    return l("filter_europe",    lang)
        case .australia: return l("filter_australia", lang)
        case .canada:    return l("filter_canada",    lang)
        case .singapore: return l("filter_singapore", lang)
        case .china:     return l("filter_china",     lang)
        case .other:     return l("filter_other",     lang)
        }
    }

    // Countries that fall under the Europe tab (UK has its own tab)
    static let europeCountries: Set<Country> = [
        .switzerland, .germany, .france, .netherlands, .sweden, .denmark, .belgium,
        .italy, .spain, .norway, .finland, .austria, .ireland
    ]

    // Countries that fall under the Other tab (Hong Kong is grouped under China)
    static let otherCountries: Set<Country> = [
        .japan, .southKorea, .taiwan, .newZealand, .israel
    ]

    func matches(_ country: Country) -> Bool {
        switch self {
        case .all:       return true
        case .us:        return country == .us
        case .uk:        return country == .uk
        case .australia: return country == .australia
        case .canada:    return country == .canada
        case .singapore: return country == .singapore
        case .china:     return country == .china || country == .hongKong
        case .europe:    return FilterTab.europeCountries.contains(country)
        case .other:     return FilterTab.otherCountries.contains(country)
        }
    }

    // The default order of reorderable tabs (all except .all)
    static var defaultTabOrder: [FilterTab] {
        [.us, .uk, .europe, .australia, .canada, .singapore, .china, .other]
    }

    // Parse a comma-separated string from UserDefaults into an ordered array,
    // appending any newly-added tabs that aren't yet saved.
    static func orderedTabs(from raw: String) -> [FilterTab] {
        let saved = raw.split(separator: ",").compactMap { FilterTab(rawValue: String($0)) }
        let merged = saved + defaultTabOrder.filter { !saved.contains($0) }
        return merged
    }
}
