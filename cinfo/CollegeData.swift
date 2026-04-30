//
//  CollegeData.swift
//  cinfo
//
//  CollegeStore is the single source of truth for university data.
//  Inject it at the root via .environmentObject(CollegeStore()) and read it
//  with @EnvironmentObject var store: CollegeStore in child views.
//
//  When RemoteDataService downloads a new CSV it posts .rankingDataRefreshed;
//  CollegeStore observes that notification and reloads automatically.
//

import Foundation
import Combine

final class CollegeStore: ObservableObject {

    @Published private(set) var colleges: [College] = []

    /// Maps college.id → its position (1-based) in the full list sorted by
    /// overall average rank. This never changes with search/filter, so the
    /// "Overall #7" badge on a card is always the global rank.
    private(set) var globalOverallRanks: [UUID: Int] = [:]

    /// ISO-8601 date string of the last successful remote update, or nil.
    @Published private(set) var lastRemoteUpdate: String? = {
        UserDefaults.standard.string(forKey: "rankingLastRemoteUpdate")
    }()

    private var cancellable: AnyCancellable?

    init() {
        colleges = DataLoader.loadColleges()
        rebuildGlobalRanks()

        // Listen for the notification posted by RemoteDataService after a
        // successful download, then reload from the freshly-saved cache file.
        cancellable = NotificationCenter.default
            .publisher(for: .rankingDataRefreshed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reload() }
    }

    private func rebuildGlobalRanks() {
        let sorted = colleges.sorted { $0.sortValue(for: .overall) < $1.sortValue(for: .overall) }
        globalOverallRanks = Dictionary(
            uniqueKeysWithValues: sorted.enumerated().map { i, c in (c.id, i + 1) }
        )
    }

    private func reload() {
        let fresh = DataLoader.loadColleges()
        guard !fresh.isEmpty else { return }
        colleges = fresh
        rebuildGlobalRanks()

        let stamp = ISO8601DateFormatter().string(from: Date())
        lastRemoteUpdate = stamp
        UserDefaults.standard.set(stamp, forKey: "rankingLastRemoteUpdate")
    }
}
