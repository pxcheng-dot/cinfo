//
//  SettingsView.swift
//  cinfo
//
//  Lets users choose appearance (Light / Dark / Auto) and language (English / Mandarin).
//  Both preferences are persisted via @AppStorage and take effect immediately.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("appColorScheme") private var colorSchemeKey  = "dark"
    @AppStorage("appLanguage")    private var lang            = "en"
    @AppStorage("homeCurrency")   private var homeCurrency    = "USD"
    @AppStorage("autoAddAIMatchSchoolsToMySchools") private var autoAddAIMatchSchoolsToMySchools = true
    @EnvironmentObject private var apiKeyStore: APIKeyStore
    @EnvironmentObject private var aiSettings:  AISettings
    @State private var showKeys = false

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

                // ── Match → My Schools ────────────────────────────────────────
                Section {
                    Toggle(isOn: $autoAddAIMatchSchoolsToMySchools) {
                        Text(l("settings_auto_add_ai_schools", lang))
                    }
                } header: {
                    Text(l("settings_match_section", lang))
                } footer: {
                    Text(l("settings_auto_add_ai_schools_footer", lang))
                }

                // ── AI Provider ───────────────────────────────────────────────
                Section(header: Text("AI Provider")) {
                    ForEach(AIProvider.allCases) { provider in
                        Button {
                            aiSettings.selectProvider(provider)
                        } label: {
                            HStack(spacing: 12) {
                                ProviderLogoView(provider: provider, size: 28)
                                Text(provider.rawValue).foregroundStyle(.primary)
                                Spacer()
                                if aiSettings.provider == provider {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // ── AI Model ──────────────────────────────────────────────────
                Section(header: Text("Model  ·  \(aiSettings.provider.rawValue)")) {
                    ForEach(aiSettings.provider.models) { model in
                        Button {
                            aiSettings.modelId = model.id
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.displayName).foregroundStyle(.primary)
                                    if let note = model.note {
                                        Text(note)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if aiSettings.modelId == model.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                // ── API Keys ──────────────────────────────────────────────────
                Section {
                    ForEach(AIProvider.allCases) { provider in
                        HStack(spacing: 12) {
                            ProviderLogoView(provider: provider, size: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(provider.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if showKeys {
                                    TextField(provider.keyPlaceholder,
                                              text: apiKeyStore.binding(for: provider))
                                        .font(.footnote)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField(provider.keyPlaceholder,
                                                text: apiKeyStore.binding(for: provider))
                                        .font(.footnote)
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }
                            }
                            Button { showKeys.toggle() } label: {
                                Image(systemName: showKeys ? "eye.slash" : "eye")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text("API Keys")
                } footer: {
                    Text("Keys are stored in the device Keychain. Get them at \(aiSettings.provider.keyHelpURL)")
                }

                // ── Home Currency ─────────────────────────────────────────────
                Section {
                    ForEach(SupportedCurrency.all) { cur in
                        Button {
                            homeCurrency = cur.code
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: cur.sfSymbol)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(cur.name)
                                        .foregroundStyle(.primary)
                                    Text(cur.code)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(cur.symbol)
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                if homeCurrency == cur.code {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text(l("home_currency", lang))
                } footer: {
                    Text(l("home_currency_hint", lang))
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
