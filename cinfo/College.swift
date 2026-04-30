//
//  College.swift
//  cinfo
//
//  Data model for a university.
//  Rankings are stored per-year so the CSV can hold up to 5 years of history.
//  All existing views keep working unchanged — rankQS, rankTimes, etc. are
//  computed properties that return the most recent available year's value.
//

import Foundation

// Which ranking system is currently active — used both for sorting and card highlighting.
enum RankingSystem: String, CaseIterable, Identifiable {
    case overall  = "Overall"
    case qs       = "QS"
    case times    = "Times"
    case usNews   = "USNews"
    case shanghai = "Shanghai"

    var id: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .overall:  return "trophy.fill"
        case .qs:       return "globe"
        case .times:    return "clock.fill"
        case .usNews:   return "newspaper.fill"
        case .shanghai: return "building.2.fill"
        }
    }
}

// Per-year snapshot of the four ranking values.
struct YearRankings {
    let qs:       Int?
    let times:    Int?
    let usNews:   Int?
    let shanghai: Int?

    static let empty = YearRankings(qs: nil, times: nil, usNews: nil, shanghai: nil)
}

struct College: Identifiable {

    let id = UUID()

    let name:        String
    let country:     Country
    let description: String
    let tuitionUSD:  Int
    var websiteURL:  String

    // Historical data keyed by calendar year (e.g. 2026, 2025 …).
    // The app always surfaces the most recent year that has any data.
    let yearlyRankings: [Int: YearRankings]

    // The calendar year considered "current" — update each release cycle.
    static let currentYear = 2026

    // MARK: – Latest-year convenience (backward-compatible with all existing views)

    var rankQS:       Int? { latestRank(\.qs) }
    var rankTimes:    Int? { latestRank(\.times) }
    var rankUSNews:   Int? { latestRank(\.usNews) }
    var rankShanghai: Int? { latestRank(\.shanghai) }

    /// Walks backwards from currentYear until it finds a non-nil value.
    private func latestRank(_ keyPath: KeyPath<YearRankings, Int?>) -> Int? {
        for year in stride(from: Self.currentYear, through: Self.currentYear - 4, by: -1) {
            if let v = yearlyRankings[year]?[keyPath: keyPath] { return v }
        }
        return nil
    }

    // MARK: – Computed average / sort helpers (unchanged API)

    var averageRank: Double? {
        let available = [rankQS, rankTimes, rankUSNews, rankShanghai].compactMap { $0 }
        guard !available.isEmpty else { return nil }
        return Double(available.reduce(0, +)) / Double(available.count)
    }

    func rank(for system: RankingSystem) -> Int? {
        switch system {
        case .overall:  return nil
        case .qs:       return rankQS
        case .times:    return rankTimes
        case .usNews:   return rankUSNews
        case .shanghai: return rankShanghai
        }
    }

    func sortValue(for system: RankingSystem) -> Double {
        switch system {
        case .overall:  return averageRank ?? .infinity
        default:        return rank(for: system).map { Double($0) } ?? .infinity
        }
    }

    // MARK: – Year-specific access (for future trend / history views)

    func rankings(for year: Int) -> YearRankings {
        yearlyRankings[year] ?? .empty
    }

    /// Sorted list of years that have at least one ranking value.
    var availableYears: [Int] {
        yearlyRankings
            .filter { yr in
                let r = yr.value
                return r.qs != nil || r.times != nil || r.usNews != nil || r.shanghai != nil
            }
            .map(\.key)
            .sorted(by: >)
    }
}

// MARK: – Country

enum Country: String, CaseIterable {
    case us          = "United States"
    case uk          = "United Kingdom"
    case australia   = "Australia"
    case singapore   = "Singapore"
    case canada      = "Canada"
    case china       = "China"
    case switzerland = "Switzerland"
    case germany     = "Germany"
    case france      = "France"
    case netherlands = "Netherlands"
    case sweden      = "Sweden"
    case denmark     = "Denmark"
    case belgium     = "Belgium"
    case italy       = "Italy"
    case spain       = "Spain"
    case norway      = "Norway"
    case finland     = "Finland"
    case austria     = "Austria"
    case ireland     = "Ireland"
    case japan       = "Japan"
    case southKorea  = "South Korea"
    case hongKong    = "Hong Kong"
    case taiwan      = "Taiwan"
    case newZealand  = "New Zealand"
    case israel      = "Israel"

    var abbr: String {
        switch self {
        case .us:          return "USA"
        case .uk:          return "UK"
        case .australia:   return "AUS"
        case .singapore:   return "SGP"
        case .canada:      return "CAN"
        case .china:       return "China"
        case .switzerland: return "Swiss"
        case .germany:     return "GER"
        case .france:      return "FRA"
        case .netherlands: return "NL"
        case .sweden:      return "SWE"
        case .denmark:     return "DEN"
        case .belgium:     return "BEL"
        case .italy:       return "ITA"
        case .spain:       return "ESP"
        case .norway:      return "NOR"
        case .finland:     return "FIN"
        case .austria:     return "AUT"
        case .ireland:     return "IRL"
        case .japan:       return "JPN"
        case .southKorea:  return "KOR"
        case .hongKong:    return "HKG"
        case .taiwan:      return "TWN"
        case .newZealand:  return "NZL"
        case .israel:      return "ISR"
        }
    }

    /// ISO-4217 code for the country's primary currency.
    var currencyCode: String {
        switch self {
        case .us:                                           return "USD"
        case .uk:                                           return "GBP"
        case .australia:                                    return "AUD"
        case .singapore:                                    return "SGD"
        case .canada:                                       return "CAD"
        case .china:                                        return "CNY"
        case .hongKong:                                     return "HKD"
        case .taiwan:                                       return "TWD"
        case .switzerland:                                  return "CHF"
        case .sweden:                                       return "SEK"
        case .denmark:                                      return "DKK"
        case .norway:                                       return "NOK"
        case .japan:                                        return "JPY"
        case .southKorea:                                   return "KRW"
        case .newZealand:                                   return "NZD"
        case .israel:                                       return "ILS"
        case .germany, .france, .netherlands, .belgium,
             .italy, .spain, .finland, .austria, .ireland:  return "EUR"
        }
    }

    var flag: String {
        switch self {
        case .us:          return "🇺🇸"
        case .uk:          return "🇬🇧"
        case .australia:   return "🇦🇺"
        case .singapore:   return "🇸🇬"
        case .canada:      return "🇨🇦"
        case .china:       return "🇨🇳"
        case .switzerland: return "🇨🇭"
        case .germany:     return "🇩🇪"
        case .france:      return "🇫🇷"
        case .netherlands: return "🇳🇱"
        case .sweden:      return "🇸🇪"
        case .denmark:     return "🇩🇰"
        case .belgium:     return "🇧🇪"
        case .italy:       return "🇮🇹"
        case .spain:       return "🇪🇸"
        case .norway:      return "🇳🇴"
        case .finland:     return "🇫🇮"
        case .austria:     return "🇦🇹"
        case .ireland:     return "🇮🇪"
        case .japan:       return "🇯🇵"
        case .southKorea:  return "🇰🇷"
        case .hongKong:    return "🇭🇰"
        case .taiwan:      return "🇹🇼"
        case .newZealand:  return "🇳🇿"
        case .israel:      return "🇮🇱"
        }
    }
}
