//
//  RankingTrendView.swift
//  cinfo
//
//  Shows a multi-year ranking trend for a single university.
//  • Line chart: X = year, Y = rank (inverted so #1 is at the top).
//  • Each ranking system is independently toggleable.
//  • "Overall" line plots the average of all available systems per year.
//  • Requires iOS 16+ (Swift Charts).
//

import SwiftUI
import Charts

// MARK: – Data helpers

private struct RankPoint: Identifiable {
    let id     = UUID()
    let system: RankingSystem
    let year:   Int
    let rank:   Double        // positive rank number (e.g. 42)
    var plotY:  Double { -rank }  // negated so #1 is highest on chart
}

private extension RankingSystem {
    var color: Color {
        switch self {
        case .overall:  return .gray
        case .qs:       return .blue
        case .times:    return .orange
        case .usNews:   return .red
        case .shanghai: return .green
        }
    }
}

// MARK: – View

struct RankingTrendView: View {

    let college:     College
    let overallRank: Int          // current positional rank (for display only)

    @State private var visible: Set<RankingSystem>
    @AppStorage("appLanguage") private var lang = "en"
    @Environment(\.dismiss) private var dismiss

    private let years = [2022, 2023, 2024, 2025, 2026]

    init(college: College, overallRank: Int, initialSystem: RankingSystem) {
        self.college     = college
        self.overallRank = overallRank
        // Pre-select the tapped system plus Overall for context
        _visible = State(initialValue: [initialSystem, .overall])
    }

    // MARK: – Computed data

    /// Average of all available raw ranks for a given year.
    private func overallValue(year: Int) -> Double? {
        let yr   = college.rankings(for: year)
        let vals = [yr.qs, yr.times, yr.usNews, yr.shanghai].compactMap { $0 }
        guard !vals.isEmpty else { return nil }
        return Double(vals.reduce(0, +)) / Double(vals.count)
    }

    private func value(system: RankingSystem, year: Int) -> Double? {
        if system == .overall { return overallValue(year: year) }
        let yr = college.rankings(for: year)
        switch system {
        case .qs:       return yr.qs.map       { Double($0) }
        case .times:    return yr.times.map    { Double($0) }
        case .usNews:   return yr.usNews.map   { Double($0) }
        case .shanghai: return yr.shanghai.map { Double($0) }
        case .overall:  return nil
        }
    }

    private var points: [RankPoint] {
        RankingSystem.allCases.flatMap { system -> [RankPoint] in
            guard visible.contains(system) else { return [] }
            return years.compactMap { year in
                guard let r = value(system: system, year: year) else { return nil }
                return RankPoint(system: system, year: year, rank: r)
            }
        }
    }

    /// Pre-computes whether each dot's label should sit above or below it.
    /// Within each year group, points are sorted best→worst (ascending rank)
    /// and assigned alternating positions so labels don't pile up.
    private var labelPositions: [String: AnnotationPosition] {
        var result: [String: AnnotationPosition] = [:]
        let byYear = Dictionary(grouping: points, by: \.year)
        for (_, group) in byYear {
            let sorted = group.sorted { $0.rank < $1.rank }
            for (i, pt) in sorted.enumerated() {
                result["\(pt.system.rawValue)_\(pt.year)"] =
                    i.isMultiple(of: 2) ? .top : .bottom
            }
        }
        return result
    }

    private func labelPosition(for pt: RankPoint) -> AnnotationPosition {
        labelPositions["\(pt.system.rawValue)_\(pt.year)"] ?? .top
    }

    /// Y-axis lower bound (most negative = worst rank shown).
    /// Round down to nearest 50 for breathing room.
    private var yMin: Double {
        let worst = points.map(\.rank).max() ?? 100
        return -(worst / 50).rounded(.up) * 50
    }

    private var hasData: Bool { !points.isEmpty }

    // MARK: – Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // ── University header ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(college.country.flag)  \(college.country.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(college.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // ── Overall rank banner ─────────────────────────────────
                    OverallRankBanner(overallRank: overallRank, college: college)
                        .padding(.horizontal)

                    // ── System toggles ──────────────────────────────────────
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(RankingSystem.allCases, id: \.self) { system in
                                Toggle(isOn: Binding(
                                    get: { visible.contains(system) },
                                    set: { on in
                                        if on { visible.insert(system) }
                                        else  { visible.remove(system) }
                                    }
                                )) {
                                    Text(system == .overall ? "Average" : system.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .toggleStyle(ChipToggleStyle(color: system.color))
                            }
                        }
                        .padding(.horizontal)
                    }

                    // ── Chart ───────────────────────────────────────────────
                    Group {
                        if hasData {
                            Chart {
                                ForEach(RankingSystem.allCases, id: \.self) { system in
                                    if visible.contains(system) {
                                        let systemPoints = points.filter { $0.system == system }
                                        ForEach(systemPoints) { pt in
                                            LineMark(
                                                x: .value("Year", pt.year),
                                                y: .value("Rank",  pt.plotY)
                                            )
                                            .foregroundStyle(system.color)
                                            .interpolationMethod(.catmullRom)

                                            PointMark(
                                                x: .value("Year", pt.year),
                                                y: .value("Rank",  pt.plotY)
                                            )
                                            .foregroundStyle(system.color)
                                            .annotation(position: labelPosition(for: pt),
                                                        spacing: 4) {
                                                if visible.count <= 2 {
                                                    Text("#\(Int(pt.rank.rounded()))")
                                                        .font(.system(size: 9, weight: .semibold))
                                                        .foregroundStyle(system.color)
                                                }
                                            }
                                        }
                                        .symbol(by: .value("System", system.rawValue))
                                        .foregroundStyle(by: .value("System", system.rawValue))
                                    }
                                }
                            }
                            // Negated values: -1 is the best (top), yMin is the worst (bottom).
                            .chartYScale(domain: yMin ... -1)
                            .chartXScale(domain: 2021.5 ... 2026.5)
                            .chartXAxis {
                                AxisMarks(values: years) { val in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        if let y = val.as(Int.self) {
                                            Text(String(y))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks { val in
                                    AxisGridLine()
                                    AxisTick()
                                    AxisValueLabel {
                                        // Convert negative plot value back to positive rank label
                                        if let v = val.as(Double.self) {
                                            Text("#\(Int(abs(v)))")
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .chartForegroundStyleScale(
                                domain: RankingSystem.allCases.map(\.rawValue),
                                range:  RankingSystem.allCases.map(\.color)
                            )
                            .chartLegend(.hidden)
                            .frame(height: 300)
                            .padding(.horizontal)
                        } else {
                            ContentUnavailableView(
                                "No Ranking Data",
                                systemImage: "chart.line.uptrend.xyaxis",
                                description: Text("Select at least one ranking system above, or data may not be available for this university.")
                            )
                            .frame(height: 220)
                        }
                    }

                    // ── Raw data table ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Raw Data")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 10)

                        // Header
                        HStack {
                            Text("System")
                                .font(.caption).foregroundStyle(.secondary)
                                .frame(width: 72, alignment: .leading)
                            ForEach(years.reversed(), id: \.self) { yr in
                                Text(String(yr))
                                    .font(.caption).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 6)

                        Divider().padding(.horizontal)

                        ForEach(RankingSystem.allCases, id: \.self) { system in
                            HStack {
                                Text(system == .overall ? "Average" : system.rawValue)
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(system.color)
                                    .frame(width: 72, alignment: .leading)
                                ForEach(years.reversed(), id: \.self) { yr in
                                    let v = value(system: system, year: yr)
                                    Text(v.map { "#\(Int($0.rounded()))" } ?? "—")
                                        .font(.caption)
                                        .foregroundStyle(v != nil ? .primary : .quaternary)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 7)
                            Divider().padding(.horizontal)
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator), lineWidth: 0.5))
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle(college.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
        }
    }
}

// MARK: – Overall rank banner

private struct OverallRankBanner: View {
    let overallRank: Int
    let college: College

    var body: some View {
        HStack(spacing: 12) {
            // Rank badge
            ZStack {
                LinearGradient(colors: [.purple, Color(red: 0.5, green: 0.1, blue: 0.9)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(spacing: 0) {
                    Text("SRS")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("#\(overallRank)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    if let score = college.compositeScore {
                        Text(String(format: "%.1f / 100", score))
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .fixedSize()
            .shadow(color: .purple.opacity(0.35), radius: 8, y: 4)

            // Explanation
            VStack(alignment: .leading, spacing: 3) {
                Text("SRS is a multi-factor model that provides student-first ranking for universities around the world. It blends temporally-weighted academic achievement with selectivity, financial strength, concentrated excellence, institutional focus, and career opportunities. SRS measures how well a university enables students to thrive.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(colors: [.purple.opacity(0.6), .purple.opacity(0.2)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: – Chip toggle style

private struct ChipToggleStyle: ToggleStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            configuration.label
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(configuration.isOn ? color : Color(.systemGray5))
                .foregroundStyle(configuration.isOn ? .white : .secondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: configuration.isOn)
    }
}
