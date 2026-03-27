import SwiftUI
import UIKit
import PhotosUI

/// 全螢幕相簿選擇器（支援多圖）
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    var selectionLimit: Int = 0  // 0 表示無限制
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = selectionLimit
        config.selection = .ordered

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard !results.isEmpty else { return }

            let parentRef = parent

            // 使用串行處理來避免並發問題
            Task { @MainActor in
                var loadedImages: [(Int, UIImage)] = []

                for (index, result) in results.enumerated() {
                    let provider = result.itemProvider
                    if provider.canLoadObject(ofClass: UIImage.self) {
                        if let image = await Self.loadImage(from: provider) {
                            loadedImages.append((index, image))
                        }
                    }
                }

                // 按照原始順序排序
                let sortedImages = loadedImages.sorted { $0.0 < $1.0 }.map { $0.1 }
                parentRef.images = sortedImages
            }
        }

        private static func loadImage(from provider: NSItemProvider) async -> UIImage? {
            await withCheckedContinuation { continuation in
                provider.loadObject(ofClass: UIImage.self) { loadedImage, _ in
                    continuation.resume(returning: loadedImage as? UIImage)
                }
            }
        }
    }
}

/// 單圖相簿選擇器（向後相容）
struct SinglePhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: SinglePhotoPicker

        init(_ parent: SinglePhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()

            guard let provider = results.first?.itemProvider else { return }

            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { [weak self] loadedImage, _ in
                    let image = loadedImage as? UIImage
                    Task { @MainActor in
                        self?.parent.image = image
                    }
                }
            }
        }
    }
}
