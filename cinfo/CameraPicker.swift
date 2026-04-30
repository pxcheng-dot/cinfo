//
//  CameraPicker.swift
//  cinfo
//
//  UIViewControllerRepresentable wrapper around UIImagePickerController
//  for camera capture. Requires NSCameraUsageDescription in Info.plist.
//

import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {

    /// Called with the captured image on success; also dismisses the sheet.
    let onCapture: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType         = .camera
        picker.cameraCaptureMode  = .photo
        picker.allowsEditing      = false
        picker.delegate           = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    // MARK: – Coordinator

    final class Coordinator: NSObject,
                              UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate {

        let parent: CameraPicker

        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
