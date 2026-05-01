//
//  FilesView.swift
//  cinfo
//
//  Lets users upload documents and photos for AI context.
//  Supports: document picker, camera capture, photo library.
//  Photos are OCR-scanned automatically; images can be converted to PDF.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct FilesView: View {

    @EnvironmentObject private var fileStore: UserFileStore
    @AppStorage("appLanguage") private var lang = "en"

    // Sheet / picker state
    @State private var showDocPicker     = false
    @State private var showCamera        = false
    @State private var showPhotosPicker  = false
    @State private var photosItem:       PhotosPickerItem?
    @State private var importError:      String?
    @State private var convertError:     String?


    var body: some View {
        NavigationStack {
            Group {
                if fileStore.files.isEmpty {
                    emptyPlaceholder
                } else {
                    fileList
                }
            }
            .navigationTitle("Files")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { toolbarContent }

            // ── Document picker ────────────────────────────────────────────
            .fileImporter(
                isPresented: $showDocPicker,
                allowedContentTypes: [.pdf, .plainText, .data],
                allowsMultipleSelection: true
            ) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        do { try fileStore.importFile(from: url) }
                        catch { importError = error.localizedDescription }
                    }
                case .failure(let err):
                    importError = err.localizedDescription
                }
            }

            // ── Photo library picker (state-driven, NOT embedded in Menu) ──
            .photosPicker(isPresented: $showPhotosPicker,
                          selection: $photosItem,
                          matching: .images)
            .onChange(of: photosItem) {
                guard let item = photosItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img  = UIImage(data: data) {
                        await fileStore.importImage(img, name: "Library Photo")
                    }
                    photosItem = nil
                }
            }

            // ── Camera sheet (only on real device) ─────────────────────────
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    showCamera = false
                    Task { await fileStore.importImage(image, name: "Camera") }
                }
                .ignoresSafeArea()
            }

            // ── Alerts ─────────────────────────────────────────────────────
            .alert("Import Error", isPresented: Binding(
                get: { importError != nil },
                set: { if !$0 { importError = nil } }
            )) {
                Button("OK") { importError = nil }
            } message: { Text(importError ?? "") }

            .alert("Conversion Error", isPresented: Binding(
                get: { convertError != nil },
                set: { if !$0 { convertError = nil } }
            )) {
                Button("OK") { convertError = nil }
            } message: { Text(convertError ?? "") }

        }
    }

    // MARK: – Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button { showDocPicker    = true } label: { Label("Browse Files",  systemImage: "folder") }
                Button { showPhotosPicker = true } label: { Label("Photo Library", systemImage: "photo") }
                Button { showCamera       = true } label: { Label("Camera",        systemImage: "camera") }
            } label: {
                Image(systemName: "plus")
            }
        }
    }

    // MARK: – File list

    private var fileList: some View {
        ScrollView {
            VStack(spacing: 12) {
                contextBanner
                    .padding(.horizontal)
                    .padding(.top, 4)

                LazyVStack(spacing: 0) {
                    ForEach(fileStore.files) { file in
                        FileRow(
                            file: file,
                            isProcessing: fileStore.processingIDs.contains(file.id),
                            thumbnail: fileStore.thumbnail(for: file),
                            onDelete: { fileStore.delete(file) },
                            onConvertToPDF: file.isImage ? {
                                Task {
                                    do    { try await fileStore.convertToPDF(file) }
                                    catch { convertError = error.localizedDescription }
                                }
                            } : nil
                        )
                        if file.id != fileStore.files.last?.id {
                            Divider().padding(.leading, 66)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator), lineWidth: 0.5))
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: – Banners / placeholders

    private var contextBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "brain")
                .foregroundStyle(Color.accentColor)
            Text("These files are automatically included as context in Match, Apply, and Budget conversations. Photos are scanned with OCR.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var emptyPlaceholder: some View {
        ContentUnavailableView {
            Label("No Files Yet", systemImage: "tray")
        } description: {
            Text("Upload documents or photos, like transcripts, CVs, recommendation letters, personal statements, test scores, certificates, portfolios, or even handwritten notes. You can also include extracurricular records, awards, research papers, internship details, and financial documents. Text is automatically extracted to give AI context, so it can provide more accurate guidance, feedback, and personalized recommendations.")
        }
    }
}

// ── File Row ──────────────────────────────────────────────────────────────────

private struct FileRow: View {
    let file:           UserFile
    let isProcessing:   Bool
    let thumbnail:      UIImage?
    let onDelete:       () -> Void
    let onConvertToPDF: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {

            // Thumbnail or icon
            Group {
                if let img = thumbnail {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: file.icon)
                        .font(.title2)
                        .foregroundStyle(file.iconColor)
                        .frame(width: 44, height: 44)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.subheadline)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("\(file.sizeString) · \(file.date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    } else if file.isImage {
                        Image(systemName: "text.viewfinder")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }

            if let convert = onConvertToPDF {
                Button { convert() } label: {
                    Label("Convert to PDF", systemImage: "doc.richtext")
                }
                .tint(.orange)
            }
        }
        .contextMenu {
            if let convert = onConvertToPDF {
                Button { convert() } label: {
                    Label("Convert to PDF", systemImage: "doc.richtext")
                }
            }
            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    FilesView()
        .environmentObject(UserFileStore())
}
