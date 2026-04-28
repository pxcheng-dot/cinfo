//
//  SafariView.swift
//  cinfo
//
//  Wraps SFSafariViewController so university websites open inside the app
//  rather than jumping to external Safari.
//

import SwiftUI
import SafariServices

// UIViewControllerRepresentable bridge to SFSafariViewController.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// Identifiable wrapper so SafariView can be used with .sheet(item:).
struct WebLink: Identifiable {
    let id = UUID()
    let url: URL
}
