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
    @State private var aiContext: AIChatContext? = nil
    @State private var showOverallInfo = false

    private var topColleges: [College] {
        Array(
            store.colleges
                .filter { $0.averageRank != nil }
                .sorted { ($0.averageRank ?? .infinity) < ($1.averageRank ?? .infinity) }
                .prefix(10)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

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
                                        subtitle: l("tab_rankings_sub", lang))
                        }
                        .buttonStyle(.plain)

                        // AI-powered cards
                        Button { aiContext = .match } label: {
                            FeatureCard(icon: "sparkles",
                                        color: .purple,
                                        title: l("tab_match", lang),
                                        subtitle: l("tab_match_sub", lang))
                        }
                        .buttonStyle(.plain)

                        Button { aiContext = .apply } label: {
                            FeatureCard(icon: "paperplane.fill",
                                        color: .orange,
                                        title: l("tab_apply", lang),
                                        subtitle: l("tab_apply_sub", lang))
                        }
                        .buttonStyle(.plain)

                        Button { aiContext = .budget } label: {
                            FeatureCard(icon: "dollarsign.circle.fill",
                                        color: .green,
                                        title: l("tab_budget", lang),
                                        subtitle: l("tab_budget_sub", lang))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // ── Top 10 Leaderboard ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Text(l("top_10", lang))
                                .font(.title2).fontWeight(.bold)
                            Button {
                                showOverallInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                        .sheet(isPresented: $showOverallInfo) {
                            OverallRankingInfoSheet()
                                .presentationDetents([.medium])
                                .presentationDragIndicator(.visible)
                        }

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
            .sheet(item: $aiContext) { ctx in
                AIChatView(context: ctx)
            }
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
    var tappable: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            Text(number)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.accentColor)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if tappable {
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color(.separator), lineWidth: 0.5))
    }
}

// ── Universities Sheet ────────────────────────────────────────────────────────
struct UniversitiesSheet: View {
    let colleges: [College]
    let lang: String
    @Environment(\.dismiss) private var dismiss
    @State private var searchText    = ""
    @State private var selectedCollege: College?

    private var displayed: [College] {
        let sorted = colleges.sorted { $0.name < $1.name }
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List(displayed) { college in
                Button {
                    selectedCollege = college
                } label: {
                    HStack(spacing: 10) {
                        Text(college.country.flag)
                        Text(college.name)
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("\(colleges.count) \(l("stat_unis", lang))")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: l("search_prompt", lang))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l("done", lang)) { dismiss() }
                }
            }
            .sheet(item: $selectedCollege) { college in
                UniversityDetailView(college: college)
            }
        }
    }
}

// ── Countries Sheet ───────────────────────────────────────────────────────────
struct CountriesSheet: View {
    let lang: String
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Country.allCases, id: \.self) { country in
                        VStack(spacing: 6) {
                            Text(country.flag).font(.largeTitle)
                            Text(country.abbr)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 0.5))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(l("countries_covered", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(l("done", lang)) { dismiss() }
                }
            }
        }
    }
}

// ── Top University Row ────────────────────────────────────────────────────────
private struct TopUniversityRow: View {
    let rank: Int
    let college: College
    let lang: String

    @State private var showDetail = false

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0,  green: 0.80, blue: 0.0)
        case 2: return Color(red: 0.72, green: 0.72, blue: 0.72)
        case 3: return Color(red: 0.80, green: 0.50, blue: 0.20)
        default: return .secondary
        }
    }

    var body: some View {
        Button { showDetail = true } label: {
            HStack(spacing: 14) {
                Text("\(rank)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(rank <= 3 ? rankColor : Color.accentColor)
                    .frame(width: 30, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(college.name)
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Text("\(college.country.flag) \(college.country.rawValue)")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            UniversityDetailView(college: college)
        }
    }
}

// ── Overall Ranking Info Sheet ────────────────────────────────────────────────
private struct OverallRankingInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Factor: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let title: String
        let detail: String
    }

    private let factors: [Factor] = [
        Factor(icon: "chart.bar.fill",       color: .blue,
               title: "Academic Achievement",
               detail: "Temporally-weighted average across QS, Times Higher Education, US News & World Report, and Shanghai ARWU, with recent years count more"),
        Factor(icon: "dollarsign.circle.fill", color: .green,
               title: "Financial Strength",
               detail: "Reflects the resources available to support students, including endowment and institutional funding"),
        Factor(icon: "lock.fill",            color: .orange,
               title: "Selectivity",
               detail: "Reflects how competitive admission is, indicating both applicant demand and student quality"),
        Factor(icon: "medal.fill",           color: .yellow,
               title: "Concentrated Excellence",
               detail: "Measures how strongly top research awards are concentrated within the institution"),
        Factor(icon: "target",               color: .purple,
               title: "Institutional Focus",
               detail: "Captures how focused an institution is, with smaller and more specialized universities receiving higher scores"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    VStack(alignment: .leading, spacing: 6) {
                        Text("SRS fuses time-weighted, independent signals into a single, intelligent measure of university performance.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)

                    VStack(spacing: 0) {
                        ForEach(Array(factors.enumerated()), id: \.element.id) { i, factor in
                            HStack(alignment: .top, spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(factor.color.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: factor.icon)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(factor.color)
                                }
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(factor.title)
                                        .font(.subheadline).fontWeight(.semibold)
                                    Text(factor.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            if i < factors.count - 1 {
                                Divider().padding(.leading, 66)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator), lineWidth: 0.5))
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("SRS Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
