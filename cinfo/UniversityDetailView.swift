//
//  UniversityDetailView.swift
//  cinfo
//
//  Full-page detail sheet for a single university.
//  Shows the long description from university_descriptions.json
//  and provides a button to open the official website in-app.
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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Country
                    Text("\(college.country.flag)  \(college.country.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Description
                    Text(longDescription)
                        .font(.body)
                        .lineSpacing(5)

                    // Inline website link
                    if let url = URL(string: college.websiteURL) {
                        Button {
                            webLink = WebLink(url: url)
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "safari")
                                    .font(.footnote)
                                Text(college.websiteURL
                                    .replacingOccurrences(of: "https://", with: "")
                                    .replacingOccurrences(of: "http://", with: ""))
                                    .font(.footnote)
                                    .underline()
                            }
                            .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.plain)
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
