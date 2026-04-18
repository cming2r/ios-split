import Foundation
import UIKit

@MainActor
class R2UploadService {
    static let shared = R2UploadService()

    private let baseURL = "https://vvmg.cc/api/split-scan"

    private init() {}

    /// 壓縮圖片：最長邊不超過 maxLength，確保 base64 後不超過 Vercel 4.5MB 限制
    private func compressImage(_ data: Data, maxLength: CGFloat = 1024) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let size = image.size
        let needsResize = max(size.width, size.height) > maxLength
        let targetImage: UIImage
        if needsResize {
            let scale = maxLength / max(size.width, size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            targetImage = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        } else {
            targetImage = image
        }
        return targetImage.jpegData(compressionQuality: 0.7) ?? data
    }

    /// 上傳收據圖片到 R2，返回公開 URL
    func uploadReceiptImage(imageData: Data, tripId: UUID, expenseId: UUID) async throws -> String {
        let compressed = compressImage(imageData)
        let base64String = compressed.base64EncodedString()

        let requestBody: [String: Any] = [
            "action": "upload",
            "image": base64String,
            "trip_id": tripId.uuidString,
            "expense_id": expenseId.uuidString
        ]

        guard let url = URL(string: baseURL) else {
            throw R2UploadError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw R2UploadError.requestFailed
        }

        guard httpResponse.statusCode == 200 else {
            throw R2UploadError.serverError(statusCode: httpResponse.statusCode)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let imageUrl = json["url"] as? String else {
            throw R2UploadError.invalidResponse
        }

        return imageUrl
    }
}

enum R2UploadError: LocalizedError {
    case invalidURL
    case requestFailed
    case serverError(statusCode: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return String(localized: "error.upload.invalidURL")
        case .requestFailed:
            return String(localized: "error.upload.requestFailed")
        case .serverError(let code):
            return String(localized: "error.upload.serverError \(code)")
        case .invalidResponse:
            return String(localized: "error.upload.invalidResponse")
        }
    }
}
