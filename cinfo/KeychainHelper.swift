//
//  KeychainHelper.swift
//  cinfo
//
//  Low-level Keychain read/write/delete for string values,
//  plus APIKeyStore — an ObservableObject wrapper so SwiftUI
//  views react to key changes just like @AppStorage would.
//

import Foundation
import Security
import Combine
import SwiftUI

// ── Low-level Keychain helpers ────────────────────────────────────────────────

enum KeychainHelper {

    static func save(_ value: String, for account: String) {
        let data = Data(value.utf8)
        // Always delete before add to avoid errSecDuplicateItem
        delete(for: account)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "cinfo",
            kSecAttrAccount: account,
            kSecValueData:   data
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    static func load(for account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      Bundle.main.bundleIdentifier ?? "cinfo",
            kSecAttrAccount:      account,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(for account: String) {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: Bundle.main.bundleIdentifier ?? "cinfo",
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// ── Reactive store ────────────────────────────────────────────────────────────

/// Single source of truth for all AI provider API keys.
/// Every key is read from / written to the Keychain — never UserDefaults.
final class APIKeyStore: ObservableObject {

    @Published var openAIKey: String {
        didSet { persist(openAIKey, account: AIProvider.openAI.keychainAccount) }
    }
    @Published var anthropicKey: String {
        didSet { persist(anthropicKey, account: AIProvider.anthropic.keychainAccount) }
    }

    init() {
        openAIKey    = KeychainHelper.load(for: AIProvider.openAI.keychainAccount)    ?? ""
        anthropicKey = KeychainHelper.load(for: AIProvider.anthropic.keychainAccount) ?? ""
    }

    // MARK: – Provider-agnostic helpers

    func key(for provider: AIProvider) -> String {
        switch provider {
        case .openAI:    return openAIKey
        case .anthropic: return anthropicKey
        }
    }

    func binding(for provider: AIProvider) -> Binding<String> {
        switch provider {
        case .openAI:    return Binding(get: { self.openAIKey },    set: { self.openAIKey    = $0 })
        case .anthropic: return Binding(get: { self.anthropicKey }, set: { self.anthropicKey = $0 })
        }
    }

    // MARK: – Private

    private func persist(_ value: String, account: String) {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { KeychainHelper.delete(for: account) }
        else               { KeychainHelper.save(trimmed, for: account) }
    }
}
