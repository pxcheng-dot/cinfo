//
//  AIChatView.swift
//  cinfo
//
//  Full-screen AI chat interface.
//  Streaming responses appear token-by-token.
//  Suggestion chips help users start a conversation quickly.
//

import SwiftUI

struct AIChatView: View {

    let context: AIChatContext

    @StateObject private var ai = AIService()
    @EnvironmentObject private var store:       CollegeStore
    @EnvironmentObject private var apiKeyStore: APIKeyStore
    @EnvironmentObject private var aiSettings:  AISettings
    @EnvironmentObject private var fileStore:   UserFileStore
    @AppStorage("appLanguage")  private var lang = "en"
    @Environment(\.dismiss)     private var dismiss

    @State private var input         = ""
    @State private var scrollProxy: ScrollViewProxy?

    // MARK: – Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if apiKeyStore.key(for: aiSettings.provider).trimmingCharacters(in: .whitespaces).isEmpty {
                    noKeyView
                } else {
                    chatBody
                }
            }
            .navigationTitle(context.navTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if ai.messages.count > 1 {
                        Button("Clear") { ai.clear(context: context) }
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .onAppear { ai.startConversation(context: context) }
    }

    // MARK: – Chat body

    private var chatBody: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(ai.messages) { msg in
                            if msg.role != .system {
                                MessageBubble(message: msg)
                                    .id(msg.id)
                            }
                        }

                        // Suggestion chips + Generate cards before first user turn
                        if ai.messages.filter({ $0.role == .user }).isEmpty {
                            SuggestionChips(suggestions: context.suggestions) { suggestion in
                                Task { await sendMessage(suggestion) }
                            }
                            .id("suggestions")

                            if context == .apply {
                                GenerateDocSection { doc in
                                    Task {
                                        await sendMessage(
                                            "Please help me write a \(doc.rawValue). " +
                                            "Ask me for the target university/program and any specific requirements."
                                        )
                                    }
                                }
                                .id("generateDocs")
                            }
                        }

                        if ai.isStreaming {
                            TypingIndicator()
                                .id("typing")
                        }

                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: ai.messages.count) {
                    withAnimation { proxy.scrollTo("bottom") }
                }
                .onChange(of: ai.messages.last?.content) {
                    proxy.scrollTo("bottom")
                }
            }

            if let err = ai.errorMessage {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            inputBar
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: – Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask anything…", text: $input, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.separator), lineWidth: 0.5))

            Button {
                let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty, !ai.isStreaming else { return }
                input = ""
                Task { await sendMessage(text) }
            } label: {
                Image(systemName: ai.isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        (input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !ai.isStreaming)
                            ? Color(.systemGray4)
                            : Color.accentColor
                    )
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !ai.isStreaming)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(
            Color(.systemBackground)
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: – No API key

    private var noKeyView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("\(aiSettings.provider.rawValue) API Key Required")
                .font(.title3.weight(.semibold))
            Text("Add your key in **Settings → AI Keys**.\nGet one at \(aiSettings.provider.keyHelpURL)")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .font(.subheadline)
            Spacer()
        }
        .padding()
    }

    // MARK: – Helpers

    private func sendMessage(_ text: String) async {
        await ai.send(text:        text,
                      provider:    aiSettings.provider,
                      modelId:     aiSettings.modelId,
                      apiKey:      apiKeyStore.key(for: aiSettings.provider),
                      colleges:    store.colleges,
                      context:     context,
                      fileContext: fileStore.combinedContext)
    }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

private struct MessageBubble: View {
    let message: ChatMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            Text(message.content.isEmpty ? " " : message.content)
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.accentColor : Color(.secondarySystemBackground))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(BubbleShape(isUser: isUser))
                .overlay(
                    BubbleShape(isUser: isUser)
                        .stroke(isUser ? Color.clear : Color(.separator), lineWidth: 0.5)
                )
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if !isUser { Spacer(minLength: 48) }
        }
    }
}

private struct BubbleShape: Shape {
    let isUser: Bool
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 16
        var p = Path()
        if isUser {
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r),
                             style: .continuous)
        } else {
            p.addRoundedRect(in: rect, cornerSize: CGSize(width: r, height: r),
                             style: .continuous)
        }
        return p
    }
}

// ── Suggestion Chips ──────────────────────────────────────────────────────────

private struct SuggestionChips: View {
    let suggestions: [String]
    let onTap: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try asking:")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)

            ForEach(suggestions, id: \.self) { s in
                Button { onTap(s) } label: {
                    Text(s)
                        .font(.subheadline)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.accentColor.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}

// ── Generate Doc Section (Apply context only) ─────────────────────────────────

private struct GenerateDocSection: View {
    let onSelect: (DocType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Generate a document:")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.leading, 4)

            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8),
                          GridItem(.flexible(), spacing: 8)],
                spacing: 8
            ) {
                ForEach(DocType.allCases) { doc in
                    Button { onSelect(doc) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: doc.icon)
                                .font(.subheadline)
                                .foregroundStyle(doc.color)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(doc.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(doc.subtitle)
                                    .font(.system(size: 9))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.separator), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 12)
    }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────

private struct TypingIndicator: View {
    @State private var phase = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == i ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15),
                               value: phase)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { phase = 1 }
    }
}
