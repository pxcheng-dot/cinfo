//
//  MainTabView.swift
//  cinfo
//
//  Root container with two tabs: Home and Settings.
//  Rankings is accessed via a card on the Home screen.
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

            FilesView()
                .tabItem { Label(l("tab_files",    lang), systemImage: "folder.fill") }

            SettingsView()
                .tabItem { Label(l("tab_settings", lang), systemImage: "gear") }
        }
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    MainTabView()
}
