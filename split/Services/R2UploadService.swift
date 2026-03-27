import Foundation

@MainActor
class R2UploadService {
    static let shared = R2UploadService()

    private let baseURL = "https://vvmg.cc/api/split-scan"

    private init() {}

    /// 上傳收據圖片到 R2，返回公開 URL
    func uploadReceiptImage(imageData: Data, tripId: UUID, expenseId: UUID) async throws -> String {
        let base64String = imageData.base64EncodedString()

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
