//
//  CollegeRow.swift
//  cinfo
//
//  Card and badge views used in the university list.
//  Separated here to keep ContentView under 200 lines.
//

import SwiftUI

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
struct CollegeRow: View {
    let college: College
    let activeRanking: RankingSystem
    // Positional rank in the sorted list (1, 2, 3…). Used for the Overall hero badge
    // and logo visibility, since College itself can't know its position in the list.
    let overallRank: Int

    @State private var webLink: WebLink?
    @AppStorage("appLanguage") private var lang = "en"

    // All systems except the active one — shown as small secondary badges
    private var otherSystems: [RankingSystem] {
        RankingSystem.allCases.filter { $0 != activeRanking }
    }

    // Effective rank for display in the hero badge
    private var heroRank: Int? {
        activeRanking == .overall ? overallRank : college.rank(for: activeRanking)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Name + country
            HStack(alignment: .center, spacing: 12) {

                VStack(alignment: .leading, spacing: 2) {
                    // Tappable name opens the university website inside the app
                    Button {
                        if let url = URL(string: college.websiteURL) {
                            webLink = WebLink(url: url)
                        }
                    } label: {
                        Text(college.name)
                            .font(.headline)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundStyle(Color.accentColor)
                    }
                    .buttonStyle(.plain)

                    Text("\(college.country.flag)  \(college.country.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Description
            Text(college.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Rankings row — active system is the large hero badge on the left
            HStack(spacing: 10) {
                HeroBadge(label: activeRanking.rawValue, rank: heroRank)

                Rectangle()
                    .fill(Color(.systemGray4))
                    .frame(width: 1, height: 36)

                ForEach(otherSystems, id: \.self) { system in
                    RankBadge(label: system.rawValue, rank: college.rank(for: system))
                }
            }

            // Tuition
            HStack {
                Image(systemName: "dollarsign.circle").foregroundStyle(.green)
                Text("~\(college.tuitionUSD.formatted(.number)) \(l("per_year_usd", lang))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.separator), lineWidth: 0.5))
        .sheet(item: $webLink) { link in
            SafariView(url: link.url)
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
