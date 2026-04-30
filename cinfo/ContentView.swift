//
//  ContentView.swift
//  cinfo
//
//  Main screen: ranking selector, reorderable country/region filter, and university list.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject private var store: CollegeStore
    @State private var searchText    = ""
    @State private var selectedTab   = FilterTab.all
    @State private var activeRanking = RankingSystem.overall

    @AppStorage("filterTabOrder")
    private var filterTabOrderRaw: String =
        FilterTab.defaultTabOrder.map(\.rawValue).joined(separator: ",")

    @AppStorage("appLanguage") private var lang = "en"

    @State private var showReorderSheet    = false
    @State private var showAllUniversities = false
    @State private var showCountries       = false
    @State private var showAI              = false

    private var countryCount: Int { Set(store.colleges.map(\.country)).count }

    private var orderedTabs: [FilterTab] {
        FilterTab.orderedTabs(from: filterTabOrderRaw)
    }

    var filteredColleges: [College] {
        store.colleges
            .filter { college in
                let matchesSearch = searchText.isEmpty ||
                    college.name.localizedCaseInsensitiveContains(searchText)
                return matchesSearch && selectedTab.matches(college.country)
            }
            .sorted { $0.sortValue(for: activeRanking) < $1.sortValue(for: activeRanking) }
    }

    var body: some View {
        VStack(spacing: 0) {

                // ── Stats strip ───────────────────────────────────────────────
                HStack(spacing: 12) {
                    Button { showAllUniversities = true } label: {
                        DiscoverStatChip(number: "\(store.colleges.count)",
                                         label: l("stat_unis", lang))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showAllUniversities) {
                        UniversitiesSheet(colleges: store.colleges, lang: lang)
                    }

                    Button { showCountries = true } label: {
                        DiscoverStatChip(number: "\(countryCount)",
                                         label: l("stat_countries", lang))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showCountries) {
                        CountriesSheet(lang: lang)
                    }

                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 4)

                // ── Ranking Selector ─────────────────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(RankingSystem.allCases, id: \.self) { system in
                            RankingTab(label: system.rawValue,
                                       symbol: system == .overall ? system.sfSymbol : nil,
                                       isActive: activeRanking == system) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    activeRanking = system
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }

                Divider()

                // ── Country / Region Filter Pills ────────────────────────────
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        FilterPill(label: l("filter_all", lang),
                                   isSelected: selectedTab == .all) {
                            selectedTab = .all
                        }
                        ForEach(orderedTabs) { tab in
                            FilterPill(label: tab.localizedLabel(lang: lang),
                                       isSelected: selectedTab == tab) {
                                selectedTab = tab
                            }
                        }
                        Button {
                            showReorderSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()

                // ── University List ───────────────────────────────────────────
                List {
                    ForEach(filteredColleges, id: \.id) { college in
                        CollegeRow(college: college,
                                   activeRanking: activeRanking,
                                   overallRank: store.globalOverallRanks[college.id] ?? 0)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color(.systemGroupedBackground))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
                .animation(.easeInOut(duration: 0.3), value: activeRanking)
            }
            .navigationTitle(l("tab_rankings", lang))
            .searchable(text: $searchText, prompt: l("search_prompt", lang))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAI = true } label: {
                        Image(systemName: "sparkles")
                    }
                }
            }
            .sheet(isPresented: $showReorderSheet) {
                FilterOrderSheet(orderRaw: $filterTabOrderRaw, lang: lang)
            }
            .sheet(isPresented: $showAI) {
                AIChatView(context: .discover)
            }
    }
}

// ── Ranking Tab ───────────────────────────────────────────────────────────────
private struct RankingTab: View {
    let label: String
    let symbol: String?
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    if let symbol = symbol {
                        Image(systemName: symbol)
                            .font(.system(size: 11, weight: isActive ? .bold : .regular))
                            .foregroundStyle(isActive ? Color.accentColor : .secondary)
                    }
                    Text(label)
                        .font(.subheadline)
                        .fontWeight(isActive ? .bold : .regular)
                        .foregroundStyle(isActive ? Color.accentColor : .secondary)
                }
                .padding(.horizontal, 6)
                Capsule()
                    .fill(isActive ? Color.accentColor : Color.clear)
                    .frame(height: 3)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

// ── Reorder Sheet ─────────────────────────────────────────────────────────────
private struct FilterOrderSheet: View {
    @Binding var orderRaw: String
    let lang: String
    @Environment(\.dismiss) private var dismiss
    @State private var items: [FilterTab]

    init(orderRaw: Binding<String>, lang: String) {
        _orderRaw = orderRaw
        self.lang = lang
        _items = State(initialValue: FilterTab.orderedTabs(from: orderRaw.wrappedValue))
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(items) { tab in
                        Label(tab.localizedLabel(lang: lang), systemImage: "line.3.horizontal")
                            .foregroundStyle(.primary)
                    }
                    .onMove { from, to in
                        items.move(fromOffsets: from, toOffset: to)
                        orderRaw = items.map(\.rawValue).joined(separator: ",")
                    }
                } header: {
                    Text(l("reorder_hint", lang))
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(l("customize_tabs", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(l("done", lang)) { dismiss() }
                }
            }
        }
    }
}

// ── Discover Stat Chip ────────────────────────────────────────────────────────
private struct DiscoverStatChip: View {
    let number: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(number)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color.accentColor)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(Color(.separator), lineWidth: 0.5))
    }
}

#Preview {
    ContentView()
}
