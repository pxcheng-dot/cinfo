//
//  UniversityDetailView.swift
//  cinfo
//
//  Full-page detail sheet for a single university.
//  Shows the long description from university_descriptions.json, campus locality /
//  institution type from university_campus_profiles.json, and a tappable
//  “Explore (school)” link to open the official site in-app.
//

import SwiftUI

struct UniversityDetailView: View {

    let college: College
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var lang = "en"
    @State private var webLink: WebLink?

    private var longDescription: String {
        DescriptionLoader.description(for: college.name) ?? college.description
    }

    private var exploreLinkTitle: String {
        String(format: l("explore_school_fmt", lang), college.exploreLinkDisplayName)
    }

    private func ownershipLabel(_ raw: String) -> String {
        switch raw.lowercased() {
        case "public":  return l("ownership_public", lang)
        case "private": return l("ownership_private", lang)
        default:        return raw.capitalized
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Country flag + locality + public / private
                    Group {
                        if let profile = CampusProfileLoader.profile(for: college.name) {
                            Text("\(college.country.flag)  \(college.country.rawValue)  ·  \(profile.location)  ·  \(ownershipLabel(profile.ownership))")
                        } else {
                            Text("\(college.country.flag)  \(college.country.rawValue)")
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                    // Description
                    Text(longDescription)
                        .font(.body)
                        .lineSpacing(5)

                    if let url = URL(string: college.websiteURL) {
                        Button {
                            webLink = WebLink(url: url)
                        } label: {
                            Text(exploreLinkTitle)
                                .font(.body)
                                .underline()
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(.isLink)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle(college.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(l("done", lang)) { dismiss() }
                }
            }
            .sheet(item: $webLink) { link in
                SafariView(url: link.url)
            }
        }
    }
}
