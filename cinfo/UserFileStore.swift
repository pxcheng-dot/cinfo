//
//  UserFileStore.swift
//  cinfo
//
//  Manages user-uploaded documents and photos. Files are stored as
//  <uuid>.<ext> inside Documents/UserFiles/. OCR text is saved in a
//  <uuid>.ocr sidecar so extraction runs only once per image.
//

import SwiftUI
import Combine
import PDFKit
import Vision
import PhotosUI
import UniformTypeIdentifiers

// ── Model ─────────────────────────────────────────────────────────────────────

struct UserFile: Identifiable, Codable, Equatable {
    let id:       UUID
    let name:     String   // original / display name
    let ext:      String   // lowercased: "pdf" "txt" "jpg" "png" "heic" …
    let date:     Date
    var byteSize: Int64

    // MARK: Helpers

    var isImage: Bool { ["jpg", "jpeg", "png", "heic", "heif"].contains(ext) }

    var sizeString: String {
        ByteCountFormatter.string(fromByteCount: byteSize, countStyle: .file)
    }

    var icon: String {
        if isImage          { return "photo"           }
        switch ext {
        case "pdf":           return "doc.richtext"
        case "docx", "doc":   return "doc.text"
        default:              return "doc.plaintext"
        }
    }

    var iconColor: Color {
        if isImage            { return .indigo }
        switch ext {
        case "pdf":             return .red
        case "docx", "doc":     return .blue
        default:                return .secondary
        }
    }
}

// ── Errors ────────────────────────────────────────────────────────────────────

enum FileStoreError: LocalizedError {
    case pdfConversionFailed
    var errorDescription: String? {
        switch self {
        case .pdfConversionFailed: return "Could not convert image to PDF."
        }
    }
}

// ── Store ─────────────────────────────────────────────────────────────────────

@MainActor
final class UserFileStore: ObservableObject {

    @Published private(set) var files: [UserFile] = []
    /// IDs currently being OCR-processed (used to show progress).
    @Published var processingIDs: Set<UUID> = []

    private let storageKey = "userFiles_v2"

    // Documents/UserFiles/<uuid>.<ext>  ← all files
    // Documents/UserFiles/<uuid>.ocr    ← extracted text sidecar
    private var filesDir: URL {
        let base = FileManager.default.urls(for: .documentDirectory,
                                            in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("UserFiles", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir,
                                                 withIntermediateDirectories: true)
        return dir
    }

    init() { load() }

    // MARK: – Import from document picker

    func importFile(from sourceURL: URL) throws {
        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessed { sourceURL.stopAccessingSecurityScopedResource() } }

        let id  = UUID()
        let ext = sourceURL.pathExtension.lowercased().ifEmpty("bin")
        let dest = filesDir.appendingPathComponent("\(id.uuidString).\(ext)")
        try FileManager.default.copyItem(at: sourceURL, to: dest)
        let size = fileSize(at: dest)

        let file = UserFile(id: id, name: sourceURL.lastPathComponent,
                            ext: ext, date: Date(), byteSize: size)
        insert(file)

        // Kick off OCR for image files in background
        if file.isImage {
            Task { await runOCR(for: file) }
        }
    }

    // MARK: – Import from camera / photo library

    /// Saves a UIImage (from camera or library) as JPEG, runs OCR.
    func importImage(_ image: UIImage, name: String = "Photo") async {
        let id   = UUID()
        let ext  = "jpg"
        let dest = filesDir.appendingPathComponent("\(id.uuidString).\(ext)")

        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        do {
            try data.write(to: dest)
        } catch { return }

        let timestamp = DateFormatter.localizedString(from: Date(),
                                                      dateStyle: .short,
                                                      timeStyle: .short)
        let file = UserFile(id: id,
                            name: "\(name) \(timestamp).jpg",
                            ext: ext,
                            date: Date(),
                            byteSize: Int64(data.count))
        insert(file)
        await runOCR(for: file)
    }

    // MARK: – Delete

    func delete(_ file: UserFile) {
        let fm = FileManager.default
        // Remove main file + OCR sidecar
        for suffix in [file.ext, "ocr"] {
            let url = filesDir.appendingPathComponent("\(file.id.uuidString).\(suffix)")
            try? fm.removeItem(at: url)
        }
        files.removeAll { $0.id == file.id }
        saveMetadata()
    }

    // MARK: – Convert image → PDF

    func convertToPDF(_ file: UserFile) async throws {
        guard file.isImage,
              let diskURL = diskURL(for: file),
              let image   = UIImage(contentsOfFile: diskURL.path)
        else { throw FileStoreError.pdfConversionFailed }

        let pdfURL = filesDir.appendingPathComponent("\(file.id.uuidString).pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: image.size))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        try data.write(to: pdfURL)

        // Remove old image file + sidecar
        try? FileManager.default.removeItem(at: diskURL)

        let pdfName = (file.name as NSString).deletingPathExtension + ".pdf"
        let updated = UserFile(id: file.id, name: pdfName, ext: "pdf",
                               date: file.date, byteSize: Int64(data.count))
        if let idx = files.firstIndex(where: { $0.id == file.id }) {
            files[idx] = updated
        }
        saveMetadata()
    }

    // MARK: – Text content

    func textContent(of file: UserFile) -> String? {
        // Check OCR sidecar first (images + any file that had OCR run)
        let sidecar = filesDir.appendingPathComponent("\(file.id.uuidString).ocr")
        if let ocr = try? String(contentsOf: sidecar, encoding: .utf8), !ocr.isEmpty {
            return ocr
        }
        guard let url = diskURL(for: file) else { return nil }
        switch file.ext {
        case "pdf":
            return PDFDocument(url: url)?.string
        case "txt", "md", "text":
            return try? String(contentsOf: url, encoding: .utf8)
        default:
            return nil
        }
    }

    /// Thumbnail for image files (loaded synchronously from disk).
    func thumbnail(for file: UserFile) -> UIImage? {
        guard file.isImage, let url = diskURL(for: file) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }

    // MARK: – AI context

    var combinedContext: String {
        guard !files.isEmpty else { return "" }
        let parts: [String] = files.compactMap { file in
            if let text = textContent(of: file), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "=== \(file.name) ===\n\(text.prefix(3000))"
            }
            return "=== \(file.name) === [no extractable text]"
        }
        return """
        The user has uploaded the following personal documents. \
        Use them to personalise your advice where relevant:

        \(parts.joined(separator: "\n\n"))
        """
    }

    // MARK: – Disk URL

    func diskURL(for file: UserFile) -> URL? {
        let url = filesDir.appendingPathComponent("\(file.id.uuidString).\(file.ext)")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: – OCR (Vision)

    func runOCR(for file: UserFile) async {
        guard file.isImage, let url = diskURL(for: file) else { return }

        await MainActor.run { processingIDs.insert(file.id) }
        defer { Task { @MainActor in processingIDs.remove(file.id) } }

        guard let cgImage = UIImage(contentsOfFile: url.path)?.cgImage else { return }

        let text: String = await withCheckedContinuation { cont in
            let request = VNRecognizeTextRequest { req, _ in
                let obs = req.results as? [VNRecognizedTextObservation] ?? []
                let str = obs.compactMap { $0.topCandidates(1).first?.string }
                              .joined(separator: "\n")
                cont.resume(returning: str)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }

        guard !text.isEmpty else { return }
        let sidecar = filesDir.appendingPathComponent("\(file.id.uuidString).ocr")
        try? text.write(to: sidecar, atomically: true, encoding: .utf8)
    }

    // MARK: – Persistence

    private func insert(_ file: UserFile) {
        files.insert(file, at: 0)
        saveMetadata()
    }

    private func load() {
        guard let data    = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([UserFile].self, from: data)
        else { return }
        files = decoded
    }

    private func saveMetadata() {
        if let data = try? JSONEncoder().encode(files) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func fileSize(at url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }
}

// MARK: – String helper

private extension String {
    func ifEmpty(_ fallback: String) -> String { isEmpty ? fallback : self }
}
