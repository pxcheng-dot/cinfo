//
//  AIService.swift
//  cinfo
//
//  Streaming AI client supporting OpenAI and Anthropic Claude.
//  Both providers use Server-Sent Events (SSE) but with different
//  JSON schemas — each has its own private streaming helper.
//

import Foundation
import SwiftUI
import Combine

// ── Message model ─────────────────────────────────────────────────────────────

struct ChatMessage: Identifiable {
    let id      = UUID()
    let role:   Role
    var content: String

    enum Role: String { case system, user, assistant }
}

// ── Document generation types ─────────────────────────────────────────────────

enum DocType: String, CaseIterable, Identifiable {
    case sop               = "Statement of Purpose"
    case personalStatement = "Personal Statement"
    case motivationLetter  = "Motivation Letter"
    case coverLetter       = "Cover Letter"
    case scholarshipEssay  = "Scholarship Essay"
    case cv                = "CV / Resume"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sop:               return "doc.text.magnifyingglass"
        case .personalStatement: return "person.text.rectangle"
        case .motivationLetter:  return "envelope.open.fill"
        case .coverLetter:       return "paperclip.circle.fill"
        case .scholarshipEssay:  return "star.bubble.fill"
        case .cv:                return "list.bullet.clipboard"
        }
    }

    var color: Color {
        switch self {
        case .sop:               return .blue
        case .personalStatement: return .purple
        case .motivationLetter:  return .orange
        case .coverLetter:       return .green
        case .scholarshipEssay:  return .yellow
        case .cv:                return .teal
        }
    }

    var subtitle: String {
        switch self {
        case .sop:               return "For graduate admissions"
        case .personalStatement: return "For undergrad / Oxbridge"
        case .motivationLetter:  return "Why this program?"
        case .coverLetter:       return "Internship or job"
        case .scholarshipEssay:  return "Funding applications"
        case .cv:                return "Academic or professional"
        }
    }
}

// ── Context presets ───────────────────────────────────────────────────────────

enum AIChatContext: Identifiable, Equatable {
    case match, apply, budget, discover
    var id: String { navTitle }

    var navTitle: String {
        switch self {
        case .match:    return "Find Best Matches"
        case .apply:    return "Apply Dream Schools"
        case .budget:   return "Plan Budget"
        case .discover: return "Explore Options"
        }
    }

    var greeting: String {
        switch self {
        case .match:
            return "Hi! I'm your university match advisor 🎓\n\nTell me about yourself — what do you want to study, which countries interest you, and what matters most in a university?\n\nIf you've uploaded personal documents in Files, I'll use them automatically."
        case .apply:
            return "Hi! I'm your application assistant ✍️\n\nI can help you plan your applications, manage deadlines, and generate documents — choose a document type below or just ask me anything.\n\nIf you've uploaded documents in Files, I'll use them automatically."
        case .budget:
            return "Hi! Let's plan your study budget 💰\n\nWhich countries or universities are you considering? Tell me your approximate budget per year and I'll help you find the best options.\n\nIf you've uploaded documents in Files, I'll use them automatically."
        case .discover:
            return "Hi! Ask me anything about universities and rankings 🔍\n\nI provide live data on 200+ leading universities across 25 countries, including the latest rankings from QS, Times Higher Education, U.S. News, and Shanghai ARWU. I also use our proprietary SRS, a six-factor model that evaluates institutions based on academic performance, selectivity, financial strength, research excellence, institutional focus, and location.\n\nWhat would you like to explore?"
        }
    }

    var suggestions: [String] {
        switch self {
        case .match:
            return ["I want to study Computer Science in the US",
                    "Best universities for medicine in Europe",
                    "Top engineering schools under $30k/year"]
        case .apply:
            return ["What are typical deadlines for UK universities?",
                    "How do I prepare for an interview?",
                    "Tips for a strong application to MIT"]
        case .budget:
            return ["Cheapest top-100 universities",
                    "Compare tuition: US vs UK vs Australia",
                    "Hidden costs of studying abroad"]
        case .discover:
            return ["Compare MIT vs Stanford vs Caltech",
                    "What does a QS ranking measure?",
                    "Which universities moved up the most recently?",
                    "Best universities for AI research globally"]
        }
    }
}

// ── Service ───────────────────────────────────────────────────────────────────

@MainActor
final class AIService: ObservableObject {

    @Published var messages:      [ChatMessage] = []
    @Published var isStreaming    = false
    @Published var errorMessage:  String?

    // MARK: – Public API

    func startConversation(context: AIChatContext) {
        messages = [ChatMessage(role: .assistant, content: context.greeting)]
    }

    func send(text: String,
              provider:    AIProvider,
              modelId:     String,
              apiKey:      String,
              colleges:    [College],
              context:     AIChatContext,
              fileContext: String = "") async {

        let key = apiKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else {
            errorMessage = "Please add your \(provider.rawValue) API key in Settings → AI."
            return
        }

        errorMessage = nil
        messages.append(ChatMessage(role: .user,      content: text))
        messages.append(ChatMessage(role: .assistant, content: ""))
        isStreaming = true
        defer { isStreaming = false }

        let systemPrompt = buildSystemPrompt(colleges: colleges, context: context,
                                             fileContext: fileContext)

        switch provider {
        case .openAI:
            await streamOpenAI(model: modelId, apiKey: key, systemPrompt: systemPrompt)
        case .anthropic:
            await streamAnthropic(model: modelId, apiKey: key, systemPrompt: systemPrompt)
        }
    }

    func clear(context: AIChatContext) {
        startConversation(context: context)
    }

    // MARK: – OpenAI streaming

    private func streamOpenAI(model: String, apiKey: String, systemPrompt: String) async {
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

        var apiMessages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        for msg in messages.dropLast() where msg.role != .system {
            apiMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("Bearer \(apiKey)",   forHTTPHeaderField: "Authorization")
        req.setValue("application/json",   forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model": model, "messages": apiMessages,
            "stream": true, "max_tokens": 1500, "temperature": 0.7
        ])

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                updateLast(openAIError(http.statusCode))
                return
            }
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                if payload == "[DONE]" { break }
                if let data    = payload.data(using: .utf8),
                   let json    = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let delta   = choices.first?["delta"] as? [String: Any],
                   let token   = delta["content"] as? String {
                    appendLast(token)
                }
            }
        } catch {
            updateLast("Something went wrong — please try again.")
        }
    }

    // MARK: – Anthropic streaming
    // Docs: https://docs.anthropic.com/en/api/messages-streaming
    // The system prompt is a top-level field; streaming events use
    // type "content_block_delta" with delta.type "text_delta".

    private func streamAnthropic(model: String, apiKey: String, systemPrompt: String) async {
        let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

        // Build messages excluding system (Anthropic uses top-level "system")
        let apiMessages: [[String: String]] = messages.dropLast()
            .filter { $0.role != .system }
            .map    { ["role": $0.role.rawValue, "content": $0.content] }

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue(apiKey,            forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",      forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json",forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "model":      model,
            "system":     systemPrompt,
            "messages":   apiMessages,
            "stream":     true,
            "max_tokens": 1500
        ])

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                updateLast(anthropicError(http.statusCode))
                return
            }
            for try await line in bytes.lines {
                guard line.hasPrefix("data: ") else { continue }
                let payload = String(line.dropFirst(6))
                if let data  = payload.data(using: .utf8),
                   let json  = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let type_ = json["type"] as? String,
                   type_ == "content_block_delta",
                   let delta = json["delta"] as? [String: Any],
                   (delta["type"] as? String) == "text_delta",
                   let token = delta["text"] as? String {
                    appendLast(token)
                }
            }
        } catch {
            updateLast("Something went wrong — please try again.")
        }
    }

    // MARK: – Error messages

    private func openAIError(_ code: Int) -> String {
        switch code {
        case 401: return "Invalid OpenAI API key — please check Settings → API Keys."
        case 403: return "Access denied (403) — your key may not have permission for this model."
        case 429: return "Quota exceeded or rate limited (429) — add credits at platform.openai.com/settings/billing, then try again."
        case 500, 502, 503: return "OpenAI server error (\(code)) — please try again in a moment."
        default:  return "OpenAI error \(code) — please try again."
        }
    }

    private func anthropicError(_ code: Int) -> String {
        switch code {
        case 401: return "Invalid Anthropic API key — please check Settings → API Keys."
        case 403: return "Access denied (403) — your key may not have permission for this model."
        case 429: return "Quota exceeded or rate limited (429) — check your usage at console.anthropic.com."
        case 500, 502, 503: return "Anthropic server error (\(code)) — please try again in a moment."
        default:  return "Anthropic error \(code) — please try again."
        }
    }

    // MARK: – System prompt

    private func buildSystemPrompt(colleges: [College],
                                    context: AIChatContext,
                                    fileContext: String = "") -> String {
        let sorted = colleges.sorted {
            ($0.averageRank ?? .infinity) < ($1.averageRank ?? .infinity)
        }
        let limit = context == .discover ? 211 : 100
        let table = sorted.prefix(limit).enumerated().map { i, c in
            let qs  = c.rankQS.map       { "\($0)" } ?? "-"
            let the = c.rankTimes.map    { "\($0)" } ?? "-"
            let usn = c.rankUSNews.map   { "\($0)" } ?? "-"
            let sha = c.rankShanghai.map { "\($0)" } ?? "-"
//            let srs: String
//            if let csv = c.csvSrsScore {
//                srs = String(format: "%.1f", csv)
//            } else if let live = c.compositeScore {
//                srs = String(format: "%.1f", live)
//            } else {
//                srs = "-"
//            }
            return "SRS #\(i+1) | \(c.name) | \(c.country.rawValue) | ~$\(c.tuitionUSD)/yr | QS:\(qs) THE:\(the) USN:\(usn) SHN:\(sha)"
        }.joined(separator: "\n")

        let srsContext = """
        SRS dataset: Each row includes SRS — the value from the bundled `srsScore` column in universities.csv (0–100, higher is better). If that field is absent, the fallback is the live composite score from the same formula. Row # is global SRS rank (#1 best).
        SRS combines six weighted signals: academic rankings 45%, admission selectivity 13.5%, financial strength 19%, concentrated excellence (Nobel/Fields/Turing affiliates) 12%, institutional focus 8.5%, career opportunity (metro centrality) 2%. It is not the same as QS, Times, US News, or Shanghai — cite SRS separately when comparing schools.
        """
        let focus: String
        switch context {
        case .match:
            focus = "Focus on matching universities to the student's profile, interests, goals, and constraints. Use any uploaded personal documents to personalise recommendations. Use SRS scores from the dataset when ranking or comparing schools as appropriate; SRS is separate from QS/Times/US News/Shanghai."
        case .discover:
            focus = """
            You are a university rankings and discovery expert with deep knowledge of the QS, \
            Times Higher Education, US News, Shanghai (ARWU), and SRS ranking systems. \
            Answer questions about universities, explain what rankings measure and how they differ, \
            compare institutions, highlight strengths and weaknesses, and help users explore and \
            interpret the data. Use the full ranking dataset provided below. Be precise with numbers. \
            When users ask about SRS, use the SRS values and context supplied below — they come from the `srsScore` column in universities.csv (with live fallback if missing).
            """
        case .apply:
            focus = """
            You are both an application strategist and an expert academic writing coach. \
            Help the student with: (1) application timelines and strategy, (2) drafting and refining \
            application documents — Statement of Purpose, Personal Statement, Motivation Letter, \
            Cover Letter, Scholarship Essay, and CV/Resume. \
            When asked to write a document, use any uploaded personal documents as source material. \
            Always ask for the target university/program and word limit if not specified. \
            Output polished, ready-to-submit prose unless the student asks for an outline first. \
            Emphasize students should actively think through and discuss their materials to ensure \
            the final work carries a genuine personal signature, rather than relying entirely on AI, \
            even when the prose is polished and ready-to-submit. 
            """
        case .budget:
            focus = "Focus on tuition costs, living expenses, scholarships, and affordable options."
        
        }

        let filePart = fileContext.isEmpty ? "" : "\n\n\(fileContext)"

        return """
        You are a knowledgeable, warm, and practical university admissions advisor.
        \(focus)

        \(srsContext)

        You have real data on 211 top universities. Rows below are ordered by SRS rank (showing up to \(limit) institutions):
        \(table)

        Guidelines:
        - Use the data above for recommendations and comparisons.
        - Ask clarifying questions before making recommendations.
        - Format lists with bullet points for readability.
        - Be encouraging and realistic about admissions.
        - Give honest estimate of the probability of being admitted.\(filePart)
        """
    }

    // MARK: – Helpers

    private func appendLast(_ token: String) {
        guard let idx = messages.indices.last else { return }
        messages[idx].content += token
    }
    private func updateLast(_ text: String) {
        guard let idx = messages.indices.last else { return }
        messages[idx].content = text
    }
}
