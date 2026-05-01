//
//  DataLoader.swift
//  cinfo
//
//  Parses universities.csv → [College].
//
//  CSV structure:
//    name, country, description, tuitionUSD, websiteURL,
//    rankQS_YYYY × 5, rankTimes_YYYY × 5,
//    rankUSNews_YYYY × 5, rankShanghai_YYYY × 5,
//    optional srsScore (0–100)
//
//  The loader is header-driven: it scans the first row for columns whose
//  names match "rank<System>_<Year>" and builds the yearlyRankings dict
//  dynamically — so adding a new year to the CSV requires no code change.
//
//  Load priority:
//    1. Documents/universities_cache.csv  (downloaded by RemoteDataService)
//    2. Bundle universities.csv           (shipped with the app)
//

import Foundation

enum DataLoader {

    // MARK: – Public entry point

    static func loadColleges() -> [College] {
        // Use the cache only if it is newer than the bundled file.
        // This ensures an app update (with a fresher bundled CSV) always wins
        // over a stale downloaded cache from a previous install.
        let useCache: Bool = {
            guard let bundleURL,
                  let bundleMod = (try? FileManager.default
                      .attributesOfItem(atPath: bundleURL.path))?[.modificationDate] as? Date,
                  let cacheMod  = (try? FileManager.default
                      .attributesOfItem(atPath: cacheURL.path))?[.modificationDate] as? Date
            else { return true } // no bundle date info → prefer cache as before
            return cacheMod > bundleMod
        }()

        if useCache, let cached = loadFrom(cacheURL) { return cached }
        if let bundled = loadFrom(bundleURL) { return bundled }
        assertionFailure("universities.csv not found in bundle")
        return []
    }

    // MARK: – File resolution

    static var cacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("universities_cache.csv")
    }

    private static var bundleURL: URL? {
        Bundle.main.url(forResource: "universities", withExtension: "csv")
    }

    // MARK: – Parsing

    private static func loadFrom(_ url: URL?) -> [College]? {
        guard let url,
              let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }

        var lines = raw.components(separatedBy: "\n")
        guard lines.count > 1 else { return nil }

        let header = parseCSVLine(lines.removeFirst().trimmingCharacters(in: .whitespacesAndNewlines))
        let columnIndex = buildColumnIndex(from: header)

        let colleges = lines.compactMap { parseCollege(from: $0, index: columnIndex) }
        return colleges.isEmpty ? nil : colleges
    }

    // MARK: – Column index

    /// Maps (system, year) → column position for ranking columns,
    /// plus fixed positions for the metadata fields.
    private struct ColumnIndex {
        let name:        Int
        let country:     Int
        let description: Int
        let tuition:     Int
        let website:     Int
        let srsScore:    Int?
        // ranking columns: key = "rankQS_2026", value = column index
        let rankCols: [String: Int]

        // All unique years found in the header, newest first
        var years: [Int] {
            Set(rankCols.keys.compactMap { Int($0.components(separatedBy: "_").last ?? "") })
                .sorted(by: >)
        }
    }

    private static func buildColumnIndex(from header: [String]) -> ColumnIndex {
        var rankCols: [String: Int] = [:]
        var name = 0, country = 1, description = 2, tuition = 3, website = 4
        var srsScore: Int?

        for (i, col) in header.enumerated() {
            switch col {
            case "name":        name        = i
            case "country":     country     = i
            case "description": description = i
            case "tuitionUSD":  tuition     = i
            case "websiteURL":  website     = i
            case "srsScore":    srsScore    = i
            default:
                // Matches "rankQS_2026", "rankTimes_2025", etc.
                let parts = col.components(separatedBy: "_")
                if parts.count == 2, parts[0].hasPrefix("rank"), Int(parts[1]) != nil {
                    rankCols[col] = i
                }
            }
        }
        return ColumnIndex(name: name, country: country, description: description,
                           tuition: tuition, website: website, srsScore: srsScore, rankCols: rankCols)
    }

    // MARK: – Row → College

    private static func parseCollege(from line: String,
                                     index ci: ColumnIndex) -> College? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let fields = parseCSVLine(trimmed)

        func field(_ i: Int) -> String {
            i < fields.count ? fields[i] : ""
        }

        guard !field(ci.name).isEmpty,
              let country    = Country(rawValue: field(ci.country)),
              let tuitionUSD = Int(field(ci.tuition)) else { return nil }

        // Build yearlyRankings from header-detected columns
        var byYear: [Int: (qs: Int?, times: Int?, usNews: Int?, shanghai: Int?)] = [:]
        for (col, colIdx) in ci.rankCols {
            guard colIdx < fields.count else { continue }
            let parts = col.components(separatedBy: "_")
            guard parts.count == 2, let year = Int(parts[1]) else { continue }
            let system = parts[0]   // e.g. "rankQS"
            let value  = Int(fields[colIdx])

            var entry = byYear[year] ?? (nil, nil, nil, nil)
            switch system {
            case "rankQS":       entry.qs       = value
            case "rankTimes":    entry.times    = value
            case "rankUSNews":   entry.usNews   = value
            case "rankShanghai": entry.shanghai = value
            default: break
            }
            byYear[year] = entry
        }

        let yearlyRankings = byYear.mapValues {
            YearRankings(qs: $0.qs, times: $0.times, usNews: $0.usNews, shanghai: $0.shanghai)
        }

        let csvSrsScore: Double? = {
            guard let idx = ci.srsScore, idx < fields.count else { return nil }
            let s = field(idx).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !s.isEmpty, let v = Double(s) else { return nil }
            return v
        }()

        return College(
            name:           field(ci.name),
            country:        country,
            description:    field(ci.description),
            tuitionUSD:     tuitionUSD,
            websiteURL:     field(ci.website),
            yearlyRankings: yearlyRankings,
            csvSrsScore:    csvSrsScore
        )
    }

    // MARK: – RFC-4180 CSV parser

    static func parseCSVLine(_ line: String) -> [String] {
        var fields:   [String] = []
        var current:  String   = ""
        var inQuotes: Bool     = false
        var index = line.startIndex

        while index < line.endIndex {
            let ch = line[index]
            if ch == "\"" {
                let next = line.index(after: index)
                if inQuotes && next < line.endIndex && line[next] == "\"" {
                    current.append("\"")
                    index = line.index(after: next)
                    continue
                }
                inQuotes.toggle()
            } else if ch == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(ch)
            }
            index = line.index(after: index)
        }
        fields.append(current)
        return fields
    }
}
