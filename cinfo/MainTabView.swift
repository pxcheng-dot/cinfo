//
//  MainTabView.swift
//  cinfo
//
//  Root tabs: Home, Backpack (files + saved schools), Settings.
//  Discover rankings open from Home.
//

import SwiftUI

struct MainTabView: View {

    @AppStorage("appColorScheme") private var colorSchemeKey = "dark"
    @AppStorage("appLanguage")    private var lang           = "en"

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeKey {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(l("tab_home",     lang), systemImage: "house.fill") }

            BackpackView()
                .tabItem { Label(l("tab_backpack", lang), systemImage: "backpack.fill") }

            SettingsView()
                .tabItem { Label(l("tab_settings", lang), systemImage: "gear") }
        }
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    MainTabView()
        .environmentObject(CollegeStore())
        .environmentObject(CurrencyService())
        .environmentObject(APIKeyStore())
        .environmentObject(AISettings())
        .environmentObject(UserFileStore())
        .environmentObject(SavedSchoolsStore())
}
