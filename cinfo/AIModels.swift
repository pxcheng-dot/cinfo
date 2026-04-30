//
//  AIModels.swift
//  cinfo
//
//  Provider and model catalogue, plus AISettings — the ObservableObject
//  that persists the user's chosen provider and model between launches.
//

import Foundation
import Combine
import SwiftUI

// ── Model ─────────────────────────────────────────────────────────────────────

struct AIModel: Identifiable, Hashable {
    let id:          String   // API identifier sent in the request
    let displayName: String
    let note:        String?  // e.g. "Recommended", "Fast", "Most capable"

    init(_ id: String, _ displayName: String, note: String? = nil) {
        self.id          = id
        self.displayName = displayName
        self.note        = note
    }
}

// ── Provider ──────────────────────────────────────────────────────────────────

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI    = "OpenAI"
    case anthropic = "Anthropic (Claude)"

    var id: String { rawValue }

    /// Bundled asset catalog name for the company logo.
    var logoAsset: String {
        switch self {
        case .openAI:    return "openai_logo"
        case .anthropic: return "anthropic_logo"
        }
    }

    /// SF Symbol fallback if the asset is missing.
    var sfSymbol: String {
        switch self {
        case .openAI:    return "brain"
        case .anthropic: return "bubble.left.and.text.bubble.right.fill"
        }
    }

    var models: [AIModel] {
        switch self {
        case .openAI:
            return [
                AIModel("gpt-4.1",           "GPT-4.1",         note: "Latest"),
                AIModel("gpt-4.1-mini",      "GPT-4.1 mini",    note: "Recommended"),
                AIModel("gpt-4.1-nano",      "GPT-4.1 nano",    note: "Fastest · Cheapest"),
                AIModel("gpt-4o",            "GPT-4o"),
                AIModel("gpt-4o-mini",       "GPT-4o mini"),
            ]
        case .anthropic:
            return [
                AIModel("claude-3-7-sonnet-20250219", "Claude 3.7 Sonnet", note: "Latest"),
                AIModel("claude-3-5-sonnet-20241022", "Claude 3.5 Sonnet", note: "Recommended"),
                AIModel("claude-3-5-haiku-20241022",  "Claude 3.5 Haiku",  note: "Fast"),
                AIModel("claude-3-opus-20240229",     "Claude 3 Opus",     note: "Most capable"),
            ]
        }
    }

    var defaultModelId: String { models[1].id }   // "Recommended" entry

    var keychainAccount: String {
        switch self {
        case .openAI:    return "openAIApiKey"
        case .anthropic: return "anthropicApiKey"
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .openAI:    return "sk-..."
        case .anthropic: return "sk-ant-..."
        }
    }

    var keyHelpURL: String {
        switch self {
        case .openAI:    return "platform.openai.com"
        case .anthropic: return "console.anthropic.com"
        }
    }
}

// ── Settings store ────────────────────────────────────────────────────────────

final class AISettings: ObservableObject {

    @Published var provider: AIProvider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: "aiProviderRaw") }
    }
    @Published var modelId: String {
        didSet { UserDefaults.standard.set(modelId, forKey: "aiModelId") }
    }

    init() {
        let raw = UserDefaults.standard.string(forKey: "aiProviderRaw") ?? AIProvider.openAI.rawValue
        let p   = AIProvider(rawValue: raw) ?? .openAI
        provider = p
        modelId  = UserDefaults.standard.string(forKey: "aiModelId") ?? p.defaultModelId
    }

    /// The currently active model, falling back to the provider default.
    var currentModel: AIModel {
        provider.models.first { $0.id == modelId } ?? provider.models[0]
    }

    /// Switch provider and reset model to that provider's default.
    func selectProvider(_ p: AIProvider) {
        provider = p
        modelId  = p.defaultModelId
    }
}

// ── Provider Logo View ────────────────────────────────────────────────────────
/// Loads the company logo via Clearbit; falls back to an SF Symbol while
/// loading or if the network is unavailable.

struct ProviderLogoView: View {
    let provider: AIProvider
    var size: CGFloat = 28

    var body: some View {
        if let uiImage = UIImage(named: provider.logoAsset) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .padding(4)
                .frame(width: size, height: size)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        } else {
            Image(systemName: provider.sfSymbol)
                .font(.system(size: size * 0.55, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .frame(width: size, height: size)
        }
    }
}
