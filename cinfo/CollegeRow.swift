//
//  CollegeRow.swift
//  cinfo
//
//  Card and badge views used in the university list.
//  Separated here to keep ContentView under 200 lines.
//

import SwiftUI
import UIKit

// ── Filter Pill Button ───────────────────────────────────────────────────────
struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

// ── College Row Card ─────────────────────────────────────────────────────────
private extension View {
    /// Dark halo so white label text stays readable on varied campus photos.
    @ViewBuilder
    func campusCardLabelShadow(enabled: Bool) -> some View {
        if enabled {
            self
                .shadow(color: .black.opacity(0.85), radius: 0, x: 0, y: 1)
                .shadow(color: .black.opacity(0.55), radius: 8, x: 0, y: 3)
        } else {
            self
        }
    }
}

struct CollegeRow: View {
    let college: College
    let activeRanking: RankingSystem
    // Positional rank in the sorted list (1, 2, 3…). Used for the Overall hero badge
    // and logo visibility, since College itself can't know its position in the list.
    let overallRank: Int

    @EnvironmentObject private var currency: CurrencyService
    @State private var showUniversityDetail = false
    @State private var trendSystem:      RankingSystem? = nil
    @State private var showHomeCurrency  = false
    @AppStorage("appLanguage")  private var lang         = "en"
    @AppStorage("homeCurrency") private var homeCurrencyCode = "USD"
    @Environment(\.colorScheme) private var colorScheme

    // Effective rank for display in the hero badge
    private var heroRank: Int? {
        activeRanking == .overall ? overallRank : college.rank(for: activeRanking)
    }

    private var campusHero: UIImage? { CampusHeroImage.uiImage(for: college.name) }

    /// In dark mode, photos and secondary backgrounds sit on near-black; a light rim keeps cards distinct.
    private var cardStrokeColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.22) : Color(.separator)
    }

    private var cardStrokeWidth: CGFloat { colorScheme == .dark ? 1 : 0.5 }

    var body: some View {
        let onPhoto = campusHero != nil

        VStack(alignment: .leading, spacing: 10) {

            // Name + country
            HStack(alignment: .center, spacing: 12) {

                VStack(alignment: .leading, spacing: 2) {
                    // Tappable name opens full description (university_descriptions.json) + official link
                    Button {
                        showUniversityDetail = true
                    } label: {
                        Text(college.name)
                            .font(.headline)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(onPhoto ? Color.white : Color.accentColor)
                            .campusCardLabelShadow(enabled: onPhoto)
                    }
                    .buttonStyle(.plain)

                    Text("\(college.country.flag)  \(college.country.rawValue)")
                        .font(.caption)
                        .foregroundStyle(onPhoto ? Color.white : Color.secondary)
                        .campusCardLabelShadow(enabled: onPhoto)
                }
            }

            // Description
            Text(college.description)
                .font(.subheadline)
                .foregroundStyle(onPhoto ? Color.white.opacity(0.96) : Color.secondary)
                .lineLimit(2)
                .campusCardLabelShadow(enabled: onPhoto)

            // Ranking badge + tuition side by side
            HStack(alignment: .center, spacing: 12) {
                Button { trendSystem = activeRanking } label: {
                    HeroBadge(label: activeRanking.rawValue, rank: heroRank)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(onPhoto ? Color.white.opacity(0.55) : Color(.systemGray4))
                    .frame(width: 1, height: 36)

                TuitionView(tuitionUSD: college.tuitionUSD,
                            localCode: college.country.currencyCode,
                            homeCode: homeCurrencyCode,
                            currency: currency,
                            lang: lang,
                            onPhotoBackdrop: onPhoto)
            }
        }
        .padding()
        .background {
            if onPhoto {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.32))
            }
        }
        .background {
            ZStack {
                if let campusHero {
                    Image(uiImage: campusHero)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    // Stronger darkening toward the bottom where most copy sits.
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.38), location: 0),
                            .init(color: .black.opacity(0.52), location: 0.38),
                            .init(color: .black.opacity(0.70), location: 0.72),
                            .init(color: .black.opacity(0.78), location: 1),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Color(.secondarySystemBackground)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(cardStrokeColor, lineWidth: cardStrokeWidth)
        )
        .sheet(isPresented: $showUniversityDetail) {
            UniversityDetailView(college: college)
        }
        .sheet(item: $trendSystem) { system in
            RankingTrendView(college: college,
                             overallRank: overallRank,
                             initialSystem: system)
        }
    }
}

// ── Tuition Toggle View ───────────────────────────────────────────────────────
/// Shows tuition in the university's local currency.
/// Tapping once converts to the user's home currency; tapping again reverts.
/// If local == home currency the row is static (nothing to toggle).
private struct TuitionView: View {

    let tuitionUSD:  Int
    let localCode:   String   // e.g. "AUD" for an Australian university
    let homeCode:    String   // user's chosen home currency
    let currency:    CurrencyService
    let lang:        String
    /// Lighter text when card uses a campus photo background.
    var onPhotoBackdrop: Bool = false

    @State private var showHome = false

    private var isSameCurrency: Bool { localCode == homeCode }

    /// Formatted amount for a given currency code.
    private func formatted(code: String) -> String? {
        let usd = Double(tuitionUSD)
        guard let amount = currency.convert(usd, to: code) else { return nil }
        let meta = currency.meta(for: code)
        let symbol = meta?.symbol ?? code
        let value  = Int(amount.rounded()).formatted(.number)
        return "~\(symbol)\(value) / year (\(code))"
    }

    var body: some View {
        let displayCode = (!isSameCurrency && showHome) ? localCode : homeCode
        let displayText = formatted(code: displayCode)
                       ?? "~$\(tuitionUSD.formatted(.number)) \(l("per_year_usd", lang))"

        Group {
            if isSameCurrency {
                Text(displayText)
                    .font(.footnote)
                    .foregroundStyle(onPhotoBackdrop ? Color.white : Color.secondary)
                    .campusCardLabelShadow(enabled: onPhotoBackdrop)
            } else {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) { showHome.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(onPhotoBackdrop ? Color.white : Color.accentColor)
                            .campusCardLabelShadow(enabled: onPhotoBackdrop)
                        Text(displayText)
                            .font(.footnote)
                            .foregroundStyle(onPhotoBackdrop ? Color.white : Color.secondary)
                            .campusCardLabelShadow(enabled: onPhotoBackdrop)
                    }
                }
                .buttonStyle(.plain)
                 }
        }
    }
}

// ── Hero Badge (active / large) ───────────────────────────────────────────────
struct HeroBadge: View {
    let label: String
    let rank: Int?

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
            Text(rank.map { "#\($0)" } ?? "—")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(minWidth: 58)
        .padding(.vertical, 8)
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// ── Rank Badge (inactive / small) ────────────────────────────────────────────
struct RankBadge: View {
    let label: String
    let rank: Int?

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Text(rank.map { "#\($0)" } ?? "—")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(rank != nil ? Color.accentColor : .secondary)
        }
        .frame(minWidth: 44)
        .padding(.vertical, 5)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
