//
//  SettingsView.swift
//  cinfo
//
//  Lets users choose appearance (Light / Dark / Auto) and language (English / Mandarin).
//  Both preferences are persisted via @AppStorage and take effect immediately.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appColorScheme") private var colorSchemeKey = "dark"
    @AppStorage("appLanguage")    private var lang           = "en"

    var body: some View {
        NavigationStack {
            List {

                // ── Appearance ────────────────────────────────────────────────
                Section {
                    AppearanceRow(icon: "sun.max.fill",   color: .orange,
                                  label: l("light", lang), key: "light",
                                  selected: $colorSchemeKey)
                    AppearanceRow(icon: "moon.fill",      color: .indigo,
                                  label: l("dark", lang),  key: "dark",
                                  selected: $colorSchemeKey)
                    AppearanceRow(icon: "circle.lefthalf.filled", color: .gray,
                                  label: l("auto", lang),  key: "auto",
                                  selected: $colorSchemeKey)
                } header: {
                    Text(l("appearance", lang))
                } footer: {
                    Text(l("appearance_hint", lang))
                }

                // ── Language ──────────────────────────────────────────────────
                Section(l("language", lang)) {
                    LanguageRow(label: l("lang_en", lang), code: "en", selected: $lang)
                    LanguageRow(label: l("lang_zh", lang), code: "zh", selected: $lang)
                }
            }
            .navigationTitle(l("tab_settings", lang))
        }
    }
}

// ── Appearance Row ────────────────────────────────────────────────────────────
private struct AppearanceRow: View {
    let icon: String
    let color: Color
    let label: String
    let key: String
    @Binding var selected: String

    var body: some View {
        Button {
            selected = key
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                if selected == key {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// ── Language Row ──────────────────────────────────────────────────────────────
private struct LanguageRow: View {
    let label: String
    let code: String
    @Binding var selected: String

    var body: some View {
        Button {
            selected = code
        } label: {
            HStack {
                Text(label).foregroundStyle(.primary)
                Spacer()
                if selected == code {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .fontWeight(.semibold)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SettingsView()
}
