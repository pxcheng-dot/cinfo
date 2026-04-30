//
//  CurrencyService.swift
//  cinfo
//
//  Fetches all currency rates vs USD from open.er-api.com (free, no API key).
//  One call populates every currency the app needs.
//  Rates are cached in UserDefaults for 24 hours; hardcoded fallbacks
//  ensure the app works offline on first launch.
//

import Foundation
import Combine

// ── Supported currencies ──────────────────────────────────────────────────────

struct SupportedCurrency: Identifiable, Hashable {
    let code:     String   // ISO 4217, e.g. "AUD"
    let symbol:   String   // Display symbol, e.g. "A$"
    let name:     String   // Full name, e.g. "Australian Dollar"
    let sfSymbol: String   // SF Symbol name for the coin icon

    var id: String { code }

    static let all: [SupportedCurrency] = [
        .init(code: "USD", symbol: "$",    name: "US Dollar",            sfSymbol: "dollarsign.circle"),
        .init(code: "GBP", symbol: "£",    name: "British Pound",        sfSymbol: "sterlingsign.circle"),
        .init(code: "AUD", symbol: "A$",   name: "Australian Dollar",    sfSymbol: "dollarsign.circle"),
        .init(code: "SGD", symbol: "S$",   name: "Singapore Dollar",     sfSymbol: "dollarsign.circle"),
        .init(code: "CAD", symbol: "C$",   name: "Canadian Dollar",      sfSymbol: "dollarsign.circle"),
        .init(code: "CNY", symbol: "¥",    name: "Chinese Yuan",         sfSymbol: "yensign.circle"),
        .init(code: "HKD", symbol: "HK$",  name: "Hong Kong Dollar",     sfSymbol: "dollarsign.circle"),
        .init(code: "TWD", symbol: "NT$",  name: "Taiwan Dollar",        sfSymbol: "dollarsign.circle"),
        .init(code: "EUR", symbol: "€",    name: "Euro",                 sfSymbol: "eurosign.circle"),
        .init(code: "CHF", symbol: "Fr",   name: "Swiss Franc",          sfSymbol: "francsign.circle"),
        .init(code: "SEK", symbol: "kr",   name: "Swedish Krona",        sfSymbol: "banknote"),
        .init(code: "DKK", symbol: "kr",   name: "Danish Krone",         sfSymbol: "banknote"),
        .init(code: "NOK", symbol: "kr",   name: "Norwegian Krone",      sfSymbol: "banknote"),
        .init(code: "JPY", symbol: "¥",    name: "Japanese Yen",         sfSymbol: "yensign.circle"),
        .init(code: "KRW", symbol: "₩",    name: "South Korean Won",     sfSymbol: "wonsign.circle"),
        .init(code: "NZD", symbol: "NZ$",  name: "New Zealand Dollar",   sfSymbol: "dollarsign.circle"),
        .init(code: "ILS", symbol: "₪",    name: "Israeli Shekel",       sfSymbol: "shekelsign.circle"),
    ]

    // Approximate fallback rates (vs USD) — used when offline on first launch.
    static let fallbackRates: [String: Double] = [
        "USD": 1.00,  "GBP": 0.79,  "AUD": 1.57,  "SGD": 1.35,
        "CAD": 1.38,  "CNY": 7.27,  "HKD": 7.79,  "TWD": 32.5,
        "EUR": 0.93,  "CHF": 0.90,  "SEK": 10.40, "DKK": 7.05,
        "NOK": 10.80, "JPY": 154.0, "KRW": 1375.0,"NZD": 1.72,
        "ILS": 3.70,
    ]
}

// ── Service ───────────────────────────────────────────────────────────────────

final class CurrencyService: ObservableObject {

    /// Live (or cached) rates, keyed by ISO-4217 code. Base = USD.
    @Published private(set) var rates: [String: Double] = SupportedCurrency.fallbackRates

    private let ratesKey     = "cachedCurrencyRatesV2"
    private let timestampKey = "cachedCurrencyRatesTimeV2"
    private let ttl: TimeInterval = 24 * 60 * 60  // 24 hours

    // free tier: https://open.er-api.com/v6/latest/USD
    private static let apiURL = URL(string: "https://open.er-api.com/v6/latest/USD")!

    init() {
        if let saved = UserDefaults.standard.object(forKey: ratesKey) as? [String: Double] {
            rates = saved
        }
        let lastFetch = UserDefaults.standard.double(forKey: timestampKey)
        if Date().timeIntervalSince1970 - lastFetch > ttl {
            Task { await fetchRates() }
        }
    }

    // MARK: – Helpers

    /// Convert a USD amount to the given currency code.  Returns nil only if
    /// both the live fetch and the fallback table have no entry for `code`.
    func convert(_ usd: Double, to code: String) -> Double? {
        guard let rate = rates[code] else { return nil }
        return usd * rate
    }

    func meta(for code: String) -> SupportedCurrency? {
        SupportedCurrency.all.first { $0.code == code }
    }

    // MARK: – Network

    private func fetchRates() async {
        do {
            let (data, _) = try await URLSession.shared.data(from: Self.apiURL)
            guard
                let json     = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let ratesAny = json["rates"] as? [String: Any]
            else { return }

            // Safely coerce each value to Double (the API can return Int for "USD": 1)
            var fetched: [String: Double] = [:]
            for (key, val) in ratesAny {
                if      let d = val as? Double { fetched[key] = d }
                else if let n = val as? NSNumber { fetched[key] = n.doubleValue }
            }

            // Keep only currencies we care about
            let needed  = Set(SupportedCurrency.all.map(\.code))
            let trimmed = fetched.filter { needed.contains($0.key) }

            await MainActor.run {
                rates = trimmed
                UserDefaults.standard.set(trimmed, forKey: ratesKey)
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: timestampKey)
            }
        } catch {
            // Network unavailable — keep the cached / fallback rates
        }
    }
}
