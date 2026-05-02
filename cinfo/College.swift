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
    case overall  = "SRS"
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

    /// `srsScore` column from `universities.csv` (0–100 snapshot). Sorting and UI use `compositeScore`; this is for export / AI context alignment with the file.
    let csvSrsScore: Double?

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

    // MARK: – Overall composite score  (v3)
    //
    // ═══════════════════════════════════════════════════════════════════════
    // Algorithm  v2  —  full specification  (recorded for reproducibility)
    // ═══════════════════════════════════════════════════════════════════════
    //
    // Goal
    // ────
    // Produce a single "Overall" score and positional rank that reflects
    // four independent dimensions of institutional quality:
    //   1. Academic rankings  (temporal-weighted cross-system average)
    //   2. Selectivity        (undergraduate acceptance rate)
    //   3. Financial strength (institutional endowment)
    //   4. Research legacy    (cumulative Nobel / Fields / Turing laureates)
    //
    // ── Component 1 : Rankings  (base weight 55 %) ──────────────────────
    //
    //   Step 1a – Per-system temporal-weighted average rank r(S)
    //   For each S ∈ {QS, Times, USNews, Shanghai}:
    //     • Collect every year Y ∈ [currentYear−4 … currentYear] with data.
    //     • Temporal weight  w(Y) = α^(currentYear−Y),  α = 0.75
    //     • r(S) = Σ[ w(Y)·rank(S,Y) ] / Σ[ w(Y) ]
    //
    //   Effective weights when all 5 years are present:
    //     currentYear − 0  (2026): 1.000  →  32.8 %
    //     currentYear − 1  (2025): 0.750  →  24.6 %
    //     currentYear − 2  (2024): 0.563  →  18.4 %
    //     currentYear − 3  (2023): 0.422  →  13.8 %
    //     currentYear − 4  (2022): 0.316  →  10.4 %
    //
    //   Step 1b – Cross-system mean
    //     r̄ = mean of r(S) over every system with ≥ 1 data point.
    //     (All four systems weighted equally — equal expertise representation.)
    //
    //   Step 1c – Normalise to 0–100 score (higher = better)
    //     rankScore = max(0,  100 × (1 − (r̄ − 1) / 249))
    //     rank 1 → 100.0 ;  rank 125 → 50.2 ;  rank 250 → 0.0
    //
    // ── Component 2 : Selectivity  (base weight 15 %) ───────────────────
    //
    //   Data: undergraduate acceptance rate  a  (%, 0–100).
    //   Note: Chinese top universities use effective Gaokao qualification
    //         rates (~0.04–0.08 %); European public universities reflect
    //         near-open-enrollment offer rates (~70–90 %).
    //
    //   selScore = max(0,  min(100,  100 − a))
    //   3 %  →  97.0 ;  15 %  →  85.0 ;  50 %  →  50.0 ;  90 %  →  10.0
    //
    // ── Component 3 : Endowment  (base weight 15 %) ─────────────────────
    //
    //   Data: total endowment  e  in USD billions.
    //   Log scale anchored at Harvard 2024 endowment ($53.2 B → ≈ 100).
    //
    //   endScore = min(100,  ln(e + 1) / ln(54.2) × 100)
    //   $53 B → 99.7 ;  $10 B → 62.1 ;  $1 B → 26.1 ;  $0.1 B → 11.5
    //
    // ── Component 4 : Award count  (base weight 15 %) ───────────────────
    //
    //   Data: all-time affiliated Nobel Prize + Fields Medal + Turing Award
    //         laureates (alumni + faculty combined).
    //   Log scale anchored at Harvard (161 laureates → ≈ 100).
    //
    //   awardScore = min(100,  ln(n + 1) / ln(162) × 100)
    //   161 → 99.8 ;  100 → 91.9 ;  30 → 69.3 ;  10 → 46.0 ;  1 → 19.4 ;  0 → 0
    //
    // ── Weighted blend ───────────────────────────────────────────────────
    //
    //   Base weights:  rankings 0.55,  selectivity 0.15,
    //                  endowment 0.15,  awards 0.15
    //
    //   Missing-data policy: if a supplemental factor is nil, its base
    //   weight is redistributed proportionally to available components.
    //   This ensures universities with partial data are not penalised by
    //   an implicit score of 0 for unknown fields.
    //
    //   compositeScore (0–100, higher = better) =
    //     Σ(available w_i × score_i) / Σ(available w_i)
    //
    // ── Positional rank ──────────────────────────────────────────────────
    //
    //   averageRank = 100 − compositeScore   (lower = better, for sorting)
    //   Sort all universities ascending by averageRank.
    //   Position in that list = "Overall" rank badge.
    //   (Computed by CollegeStore.rebuildGlobalRanks().)
    //
    // ── Constants ────────────────────────────────────────────────────────
    //   temporalDecay  α        = 0.75
    //   currentYear             = 2026
    //   historyWindow           = 5 years  (currentYear−4 … currentYear)
    //   rankFloor               = 250  (ranks beyond this score as 0)
    //   endowmentAnchorBn       = 54.2  (Harvard 2024, USD billions)
    //   awardAnchor             = 162   (Harvard all-time laureates)
    //   Weight: rankings / selectivity / endowment / awards = 55/15/15/15

    static let temporalDecay: Double = 0.75

    // ── v1-compatible internal helper ────────────────────────────────────
    // Returns the cross-system temporal-weighted average rank (lower = better).
    // Used exclusively as the rankings component of compositeScore below.
    private var temporalWeightedAvgRank: Double? {
        let decay  = Self.temporalDecay
        let kpList: [KeyPath<YearRankings, Int?>] = [\.qs, \.times, \.usNews, \.shanghai]
        var systemScores: [Double] = []
        for kp in kpList {
            var wSum = 0.0, wTot = 0.0
            for age in 0...4 {
                let w = pow(decay, Double(age))
                if let r = yearlyRankings[Self.currentYear - age]?[keyPath: kp] {
                    wSum += w * Double(r); wTot += w
                }
            }
            if wTot > 0 { systemScores.append(wSum / wTot) }
        }
        guard !systemScores.isEmpty else { return nil }
        return systemScores.reduce(0, +) / Double(systemScores.count)
    }

    // ── Composite score  (0–100, higher = better)  ───────────────────────
    //
    // v3 weights: academic rankings 45 % | selectivity 13.5 % | endowment/student 19 %
    //             research awards 12 % | institutional focus 8.5 % | location 2 %
    //
    // "Focus" rewards smaller, more specialised institutions:
    //   a concentrated $4 B endowment across 2 400 students (Caltech) ranks
    //   higher than the same sum spread over 50 000 students.
    //   Likewise, 45 laureates among 310 faculty (Caltech, density 0.145)
    //   outscores 161 laureates among 2 400 faculty (Harvard, density 0.067).
    var compositeScore: Double? {
        guard let r = temporalWeightedAvgRank else { return nil }

        let sup = SupplementalData.get(name)
        typealias WS = (weight: Double, score: Double)
        var parts: [WS] = []

        // 1 – Academic rankings (45 %)
        let rankScore = max(0.0, 100.0 * (1.0 - (r - 1.0) / 249.0))
        parts.append((0.45, rankScore))

        // 2 – Selectivity (13.5 %)
        if let a = sup.acceptanceRate {
            parts.append((0.135, max(0.0, min(100.0, 100.0 - a))))
        }

        // 3 – Endowment per student (19 %) — log scale, Princeton ~$4 012 K/student → 100
        if let e = sup.endowmentBn, e > 0,
           let s = sup.studentCount, s > 0 {
            let kUSD  = e * 1_000_000.0 / Double(s)
            let score = min(100.0, max(0.0, log(max(1.0, kUSD)) / log(4012.0) * 100.0))
            parts.append((0.19, score))
        }

        // 4 – Research awards (12 %) — log scale, Harvard 161 laureates → 100
        // Anchor = log(162) so Harvard scores 100 and all others scale below.
        if let n = sup.awardCount {
            let score = min(100.0, max(0.0,
                log(Double(max(1, n)) + 1.0) / log(162.0) * 100.0))
            parts.append((0.12, score))
        }

        // 5 – Institutional focus (8.5 %) — enrollment + school count, equal sub-weight
        let enrollFocus: Double? = sup.studentCount.map { sc in
            let c = Double(max(sc, 2_000))
            return min(100.0, max(0.0,
                (log(150_000.0) - log(c)) / (log(150_000.0) - log(2_000.0)) * 100.0))
        }
        let deptFocus: Double? = sup.schoolCount.map { dc in
            let c = Double(max(dc, 4))
            return min(100.0, max(0.0,
                (log(65.0) - log(c)) / (log(65.0) - log(4.0)) * 100.0))
        }
        if enrollFocus != nil || deptFocus != nil {
            let subs = [enrollFocus, deptFocus].compactMap { $0 }
            parts.append((0.085, subs.reduce(0, +) / Double(subs.count)))
        }

        // 6 – Location (2 %) — metro-area centrality, 0-100 pre-scored
        if let loc = sup.locationScore {
            parts.append((0.02, loc))
        }

        let totalW = parts.reduce(0.0) { $0 + $1.weight }
        let wSum   = parts.reduce(0.0) { $0 + $1.weight * $1.score }
        return wSum / totalW
    }

    /// Lower is better (rank #1 is best).  Returns nil if no ranking data.
    var averageRank: Double? { compositeScore.map { 100.0 - $0 } }

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

extension College {

    /// Preferred short name for “Explore …” official-site links (otherwise `name`).
    private static let exploreLinkShortNames: [String: String] = [
        "Massachusetts Institute of Technology": "MIT",
        "California Institute of Technology": "Caltech",
        "Harvard University": "Harvard",
        "Princeton University": "Princeton",
        "Yale University": "Yale",
        "Columbia University": "Columbia",
        "University of Pennsylvania": "Penn",
        "Cornell University": "Cornell",
        "Brown University": "Brown",
        "Dartmouth College": "Dartmouth",
        "Vanderbilt University": "Vanderbilt",
        "Washington University in St. Louis": "WUSTL",
        "Emory University": "Emory",
        "Georgetown University": "Georgetown",
        "University of California, Berkeley": "UC Berkeley",
        "University of California, Los Angeles": "UCLA",
        "University of California, San Diego": "UCSD",
        "University of Michigan–Ann Arbor": "UMich",
        "Northwestern University": "Northwestern",
        "Duke University": "Duke",
        "University of Oxford": "Oxford",
        "University of Cambridge": "Cambridge",
        "Johns Hopkins University": "JHU",
        "Carnegie Mellon University": "CMU",
        "University of Chicago": "UChicago",
        "University College London": "UCL",
        "New York University": "NYU",
        "University of Texas at Austin": "UT Austin",
        "University of Wisconsin–Madison": "UW Madison",
        "University of California, Santa Barbara": "UCSB",
        "University of California, Davis": "UCD",
    ]

    var exploreLinkDisplayName: String {
        Self.exploreLinkShortNames[name] ?? name
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
