//
//  cinfoApp.swift
//  cinfo
//

import SwiftUI

@main
struct cinfoApp: App {

    @StateObject private var store = CollegeStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .onAppear {
                    // Background fetch — returns immediately; does nothing if
                    // the remote URL isn't configured or if called < 7 days ago.
                    RemoteDataService.shared.fetchIfNeeded()
                }
        }
    }
}
