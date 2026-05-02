//
//  BackpackView.swift
//  cinfo
//
//  Root tab: vertical folder-style entries for files and saved schools.
//

import SwiftUI
import UIKit

struct BackpackView: View {

    @AppStorage("appLanguage") private var lang = "en"
    @State private var showBackpackInfo = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(l("backpack_title", lang))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)

                        Button {
                            showBackpackInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(l("backpack_info_a11y", lang))

                        Spacer(minLength: 0)
                    }

                    BackpackFolderCard(
                        title: l("backpack_my_schools", lang),
                        systemImage: "heart.fill",
                        iconTint: .red
                    ) {
                        MySchoolsFolderView()
                    }

                    BackpackFolderCard(
                        title: l("backpack_interests_folder", lang),
                        systemImage: "lightbulb.max.fill",
                        iconTint: .orange
                    ) {
                        InterestsFolderView()
                    }

                    BackpackFolderCard(
                        title: l("backpack_files_folder", lang),
                        systemImage: "folder.fill",
                        iconTint: Color.accentColor
                    ) {
                        UploadedFilesFolderView()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showBackpackInfo) {
                BackpackInfoSheet(lang: lang)
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }
}

// MARK: – Backpack info sheet

private struct BackpackInfoSheet: View {

    let lang: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(l("backpack_intro", lang))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(l("backpack_title", lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l("done", lang)) { dismiss() }
                }
            }
        }
    }
}

// MARK: – Folder-shaped tab row

private struct BackpackFolderCard<Destination: View>: View {

    let title: String
    let systemImage: String
    let iconTint: Color
    @ViewBuilder let destination: () -> Destination

    private let folderCorner: CGFloat = 14
    private let tabHeight: CGFloat = 20

    var body: some View {
        NavigationLink(destination: destination()) {
            ZStack(alignment: .topLeading) {
                folderChrome

                HStack(alignment: .center, spacing: 16) {
                    Image(systemName: systemImage)
                        .font(.system(size: 40))
                        .foregroundStyle(iconTint)
                        .symbolRenderingMode(.hierarchical)
                        .shadow(color: .black.opacity(0.06), radius: 2, y: 1)

                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 20)
                .padding(.top, tabHeight + 18)
                .padding(.bottom, 26)
            }
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
        }
        .buttonStyle(.plain)
    }

    /// Folder card aligned with grouped surfaces + accent tab strip.
    private var folderChrome: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: folderCorner, style: .continuous)
                .fill(folderGradient)

            // Tab (folder index)
            UnevenRoundedRectangle(
                topLeadingRadius: 8,
                bottomLeadingRadius: 2,
                bottomTrailingRadius: 8,
                topTrailingRadius: 8,
                style: .continuous
            )
            .fill(tabFill)
            .frame(width: min(152, 172), height: tabHeight)
            .offset(x: 14, y: -tabHeight * 0.32)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

            RoundedRectangle(cornerRadius: folderCorner, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.55), lineWidth: 0.5)
        }
    }

    private var folderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(.secondarySystemBackground),
                Color(.secondarySystemGroupedBackground),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var tabFill: LinearGradient {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.22),
                Color.accentColor.opacity(0.32),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: – My Schools

private struct MySchoolsFolderView: View {

    @EnvironmentObject private var store: CollegeStore
    @EnvironmentObject private var savedSchools: SavedSchoolsStore
    @AppStorage("appLanguage") private var lang = "en"

    var body: some View {
        Group {
            if savedSchools.entries.isEmpty {
                ContentUnavailableView {
                    Label(l("backpack_my_schools_empty_title", lang),
                          systemImage: "heart")
                } description: {
                    Text(l("backpack_my_schools_empty_detail", lang))
                }
            } else {
                List {
                    ForEach(savedSchools.entries, id: \.universityName) { entry in
                        if let college = store.colleges.first(where: { $0.name == entry.universityName }) {
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(college.name)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.primary)
                                    Text("\(college.country.flag) \(college.country.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                SchoolCategoryMenus(universityName: entry.universityName,
                                                    savedSchools: savedSchools,
                                                    lang: lang)
                            }
                            .padding(.vertical, 6)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    savedSchools.remove(entry.universityName)
                                } label: {
                                    Label(l("backpack_my_schools_remove", lang), systemImage: "trash")
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(entry.universityName)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                SchoolCategoryMenus(universityName: entry.universityName,
                                                    savedSchools: savedSchools,
                                                    lang: lang)
                            }
                            .padding(.vertical, 6)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    savedSchools.remove(entry.universityName)
                                } label: {
                                    Label(l("backpack_my_schools_remove", lang), systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(l("backpack_my_schools", lang))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

// MARK: – Interests

private struct InterestsFolderView: View {

    @AppStorage("appLanguage") private var lang = "en"

    var body: some View {
        ContentUnavailableView {
            Label(l("backpack_interests_empty_title", lang), systemImage: "lightbulb")
        } description: {
            Text(l("backpack_interests_empty_detail", lang))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(l("backpack_interests_folder", lang))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

// MARK: – My Schools pickers (popover anchor geometry)

/// Vertical center of each option chip in screen space (keyed so two pickers in one row don’t clash).
private struct PopoverAnchorMidYKey: PreferenceKey {
    static var defaultValue: [UUID: CGFloat] { [:] }
    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private func popoverReferenceScreenHeight() -> CGFloat {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .map { $0.screen.bounds.height }
        .max()
        ?? 844
}

// MARK: – Likelihood & App Status pickers (horizontal, values only)

private struct AnchoredPickPopover<Options: View>: View {

    private var rowControlHeight: CGFloat { 34 }

    let valueText: String
    let dialogTitle: String
    let accessibilityHint: String
    let lang: String
    @Binding var isPresented: Bool
    let onDismissOther: () -> Void
    @ViewBuilder let options: () -> Options

    @State private var anchorId = UUID()
    @State private var triggerMidY: CGFloat = 0
    @State private var arrowEdge: Edge = .top

    var body: some View {
        Button {
            onDismissOther()
            let h = popoverReferenceScreenHeight()
            // Upper screen: `.top` attaches popover’s top to the anchor → content opens downward.
            // Lower screen: `.bottom` → opens upward. Unknown geometry → open downward.
            if triggerMidY > 0, triggerMidY < h * 0.42 {
                arrowEdge = .top
            } else if triggerMidY > 0 {
                arrowEdge = .bottom
            } else {
                arrowEdge = .top
            }
            isPresented = true
        } label: {
            HStack(spacing: 6) {
                Text(valueText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: rowControlHeight)
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: PopoverAnchorMidYKey.self,
                    value: [anchorId: geo.frame(in: .global).midY]
                )
            }
        )
        .onPreferenceChange(PopoverAnchorMidYKey.self) { dict in
            if let y = dict[anchorId] { triggerMidY = y }
        }
        .popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds), arrowEdge: arrowEdge) {
            VStack(alignment: .leading, spacing: 0) {
                Text(dialogTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Divider()

                options()
                    .padding(.bottom, 8)
            }
            .frame(minWidth: 260)
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityLabel("\(accessibilityHint): \(valueText)")
        .accessibilityHint(l("picker_tap_to_choose_a11y", lang))
    }
}

private struct SchoolCategoryMenus: View {

    /// Same height for pills and Likelihood / Status menus (tall enough for larger menu text).
    private static let rowControlHeight: CGFloat = 34

    let universityName: String
    @ObservedObject var savedSchools: SavedSchoolsStore
    let lang: String

    @State private var showAppStatusChoices = false
    @State private var showLikelihoodChoices = false

    private var current: SavedSchoolEntry? {
        savedSchools.entry(for: universityName)
    }

    var body: some View {
        if let current {
            HStack(alignment: .center, spacing: 8) {
                if savedSchools.isMyChoice(universityName) {
                    sourcePill(text: l("my_choice_badge", lang), fill: Color.purple)
                }
                if savedSchools.isAIRecommended(universityName) {
                    sourcePill(text: l("ai_rec_badge", lang), fill: Color.accentColor)
                }

                AnchoredPickPopover(
                    valueText: current.appStatus.localized(lang),
                    dialogTitle: l("picker_school_status_a11y", lang),
                    accessibilityHint: l("picker_school_status_a11y", lang),
                    lang: lang,
                    isPresented: $showAppStatusChoices,
                    onDismissOther: { showLikelihoodChoices = false }
                ) {
                    statusOptionsList(current: current)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                AnchoredPickPopover(
                    valueText: current.likelihood.localized(lang),
                    dialogTitle: l("picker_school_likelihood_a11y", lang),
                    accessibilityHint: l("picker_school_likelihood_a11y", lang),
                    lang: lang,
                    isPresented: $showLikelihoodChoices,
                    onDismissOther: { showAppStatusChoices = false }
                ) {
                    likelihoodOptionsList(current: current)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private func statusOptionsList(current: SavedSchoolEntry) -> some View {
        ForEach(SchoolAppStatus.allCases) { status in
            Button {
                savedSchools.setAppStatus(universityName, status)
                showAppStatusChoices = false
            } label: {
                HStack {
                    Text(status.localized(lang))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 12)
                    if status == current.appStatus {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private func likelihoodOptionsList(current: SavedSchoolEntry) -> some View {
        ForEach(SchoolLikelihood.allCases) { tier in
            Button {
                savedSchools.setLikelihood(universityName, tier)
                showLikelihoodChoices = false
            } label: {
                HStack {
                    Text(tier.localized(lang))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 12)
                    if tier == current.likelihood {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private func sourcePill(text: String, fill: Color) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .padding(.horizontal, 6)
            .frame(height: Self.rowControlHeight)
            .fixedSize(horizontal: true, vertical: false)
            .background(fill)
            .clipShape(Capsule())
            .accessibilityLabel(text)
    }
}

#Preview {
    BackpackView()
        .environmentObject(UserFileStore())
        .environmentObject(CollegeStore())
        .environmentObject(SavedSchoolsStore())
}
