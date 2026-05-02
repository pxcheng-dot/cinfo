//
//  cinfoApp.swift
//  cinfo
//

import SwiftUI

@main
struct cinfoApp: App {

    @StateObject private var store       = CollegeStore()
    @StateObject private var currency    = CurrencyService()
    @StateObject private var apiKeyStore = APIKeyStore()
    @StateObject private var aiSettings  = AISettings()
    @StateObject private var fileStore      = UserFileStore()
    @StateObject private var savedSchools   = SavedSchoolsStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(store)
                .environmentObject(currency)
                .environmentObject(apiKeyStore)
                .environmentObject(aiSettings)
                .environmentObject(fileStore)
                .environmentObject(savedSchools)
                .onAppear {
                    // Background fetch — returns immediately; does nothing if
                    // the remote URL isn't configured or if called < 7 days ago.
                    RemoteDataService.shared.fetchIfNeeded()
                }
        }
    }
}
