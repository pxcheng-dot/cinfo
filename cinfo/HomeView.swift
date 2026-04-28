//
//  HomeView.swift
//  cinfo
//
//  Main dashboard: stats, feature cards (Rankings + 3 placeholders), top-10, country chips.
//

import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var store: CollegeStore
    @AppStorage("appLanguage") private var lang = "en"

    private var topColleges: [College] {
        Array(
            store.colleges
                .filter { $0.averageRank != nil }
                .sorted { ($0.averageRank ?? .infinity) < ($1.averageRank ?? .infinity) }
                .prefix(10)
        )
    }

    private var countryCount: Int { Set(store.colleges.map(\.country)).count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Stats ─────────────────────────────────────────────────
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                        spacing: 12
                    ) {
                        StatCard(number: "\(store.colleges.count)",
                                 label: l("stat_unis", lang))
                        StatCard(number: "\(countryCount)",
                                 label: l("stat_countries", lang))
                        StatCard(number: "4",
                                 label: l("stat_rankings", lang))
                    }
                    .padding(.horizontal)

                    // ── Feature Cards ─────────────────────────────────────────
                    LazyVGrid(
                        columns: [GridItem(.flexible(), spacing: 12),
                                  GridItem(.flexible(), spacing: 12)],
                        spacing: 12
                    ) {
                        // Rankings — navigates into the full list
                        NavigationLink(destination: ContentView()) {
                            FeatureCard(icon: "list.number",
                                        color: .accentColor,
                                        title: l("tab_rankings", lang),
                                        subtitle: "\(store.colleges.count) universities")
                        }
                        .buttonStyle(.plain)

                        // Placeholder cards
                        FeatureCard(icon: "ellipsis.circle",
                                    color: Color(.systemGray3),
                                    title: "—",
                                    subtitle: "Coming soon")
                        FeatureCard(icon: "ellipsis.circle",
                                    color: Color(.systemGray3),
                                    title: "—",
                                    subtitle: "Coming soon")
                        FeatureCard(icon: "ellipsis.circle",
                                    color: Color(.systemGray3),
                                    title: "—",
                                    subtitle: "Coming soon")
                    }
                    .padding(.horizontal)

                    // ── Top 10 Leaderboard ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        Text(l("top_10", lang))
                            .font(.title2).fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.bottom, 12)

                        VStack(spacing: 0) {
                            ForEach(Array(topColleges.enumerated()), id: \.element.id) { index, college in
                                TopUniversityRow(rank: index + 1, college: college, lang: lang)
                                if index < topColleges.count - 1 {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(.separator), lineWidth: 0.5))
                        .padding(.horizontal)
                    }

                    // ── Countries Covered ─────────────────────────────────────
                    VStack(alignment: .leading, spacing: 12) {
                        Text(l("countries_covered", lang))
                            .font(.title2).fontWeight(.bold)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(Country.allCases, id: \.self) { country in
                                    VStack(spacing: 4) {
                                        Text(country.flag).font(.largeTitle)
                                        Text(country.abbr)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 64)
                                    .padding(.vertical, 12)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // ── Last Updated ──────────────────────────────────────────
                    if let stamp = store.lastRemoteUpdate,
                       let date = ISO8601DateFormatter().date(from: stamp) {
                        Text("Rankings updated \(date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

// ── Feature Card ──────────────────────────────────────────────────────────────
private struct FeatureCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Spacer()
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 110)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(Color(.separator), lineWidth: 0.5))
    }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────
private struct StatCard: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Text(number)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.accentColor)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(.separator), lineWidth: 0.5))
    }
}

// ── Top University Row ────────────────────────────────────────────────────────
private struct TopUniversityRow: View {
    let rank: Int
    let college: College
    let lang: String

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0,  green: 0.80, blue: 0.0)
        case 2: return Color(red: 0.72, green: 0.72, blue: 0.72)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .secondary
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(rank <= 3 ? rankColor : Color.accentColor)
                .frame(width: 30, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(college.name)
                    .font(.subheadline).fontWeight(.semibold)
                    .lineLimit(1)
                Text("\(college.country.flag) \(college.country.rawValue)")
                    .font(.caption).foregroundStyle(.secondary)
            }

            Spacer()

            if let avg = college.averageRank {
                Text(String(format: "\(l("avg_label", lang)) %.1f", avg))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    HomeView()
}
