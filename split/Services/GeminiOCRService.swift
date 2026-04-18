import Foundation
import UIKit

// MARK: - OCR 結果（供 App 內部使用）
struct OCRResult {
    var amount: Double?
    var currency: String?
    var date: Date?
    var merchantName: String?
    var subtitle: String?
    var address: String?
    var items: [OCRItem]
    var rawText: String
    var confidence: Float
    var suggestedCategoryName: String?
    var imageUrls: [String]
}

struct OCRItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Double?
    var unitPrice: Double?
    var totalPrice: Double?
}

// MARK: - Gemini API 回應結構
struct GeminiOCRResult: Codable {
    let success: Bool
    let amount: Double?
    let currency: String?
    let date: String?
    let time: String?
    let merchantName: String?
    let subtitle: String?
    let address: String?
    let items: [ReceiptItem]
    let rawText: String
    let confidence: Double
    let imageUrls: [String]?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case success, amount, currency, date, time, merchantName, subtitle, address, items, rawText, confidence, error
        case imageUrls = "image_urls"
    }

    struct ReceiptItem: Codable {
        let name: String
        let quantity: Double?
        let unitPrice: Double?
        let totalPrice: Double?
    }
}

@MainActor
class GeminiOCRService {
    static let shared = GeminiOCRService()

    private let baseURL = "https://vvmg.cc/api/split-scan"

    private init() {}

    /// 壓縮圖片：最長邊不超過 maxLength，確保 base64 後不超過 Vercel 4.5MB 限制
    private func compressImage(_ image: UIImage, maxLength: CGFloat = 1024) -> Data? {
        let size = image.size
        let targetImage: UIImage
        if max(size.width, size.height) > maxLength {
            let scale = maxLength / max(size.width, size.height)
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            let renderer = UIGraphicsImageRenderer(size: newSize)
            targetImage = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        } else {
            targetImage = image
        }
        return targetImage.jpegData(compressionQuality: 0.7)
    }

    func recognizeReceipts(from images: [UIImage], currencyCode: String? = nil) async throws -> GeminiOCRResult {
        guard let image = images.first else {
            throw GeminiOCRError.invalidImage
        }
        guard let imageData = compressImage(image) else {
            throw GeminiOCRError.invalidImage
        }
        guard let url = URL(string: baseURL) else {
            throw GeminiOCRError.invalidURL
        }

        let base64 = imageData.base64EncodedString()

        let requestBody: [String: Any] = [
            "action": "scan",
            "image": base64,
            "language": Locale.current.language.languageCode?.identifier ?? "en",
            "country_code": FeedbackService.getCountryCode(),
            "currency_code": currencyCode ?? "XXX",
            "device_id": FeedbackService.getDeviceId()
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiOCRError.requestFailed
        }

        guard httpResponse.statusCode == 200 else {
            throw GeminiOCRError.serverError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(GeminiOCRResult.self, from: data)
    }

    func convertToOCRResult(_ geminiResult: GeminiOCRResult, timeZone: TimeZone = .current) -> OCRResult {
        var parsedDate: Date? = nil

        if let dateString = geminiResult.date {
            let formatter = DateFormatter()
            formatter.timeZone = timeZone  // 使用目的地時區

            // 如果有時間，組合日期和時間
            if let timeString = geminiResult.time {
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                parsedDate = formatter.date(from: "\(dateString) \(timeString)")
            }

            // 如果組合失敗或沒有時間，只解析日期
            if parsedDate == nil {
                formatter.dateFormat = "yyyy-MM-dd"
                parsedDate = formatter.date(from: dateString)
            }
        }

        // 根據商家名稱和內容智能推薦分類
        let suggestedCategory = suggestCategory(
            merchantName: geminiResult.merchantName,
            items: geminiResult.items,
            rawText: geminiResult.rawText
        )

        // 轉換子項目
        let ocrItems = geminiResult.items.map { item in
            OCRItem(
                name: item.name,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                totalPrice: item.totalPrice
            )
        }

        return OCRResult(
            amount: geminiResult.amount,
            currency: geminiResult.currency,
            date: parsedDate,
            merchantName: geminiResult.merchantName,
            subtitle: geminiResult.subtitle,
            address: geminiResult.address,
            items: ocrItems,
            rawText: geminiResult.rawText,
            confidence: Float(geminiResult.confidence),
            suggestedCategoryName: suggestedCategory,
            imageUrls: geminiResult.imageUrls ?? []
        )
    }

    /// 根據內容智能推薦分類
    private func suggestCategory(merchantName: String?, items: [GeminiOCRResult.ReceiptItem], rawText: String) -> String? {
        let searchText = [
            merchantName?.lowercased() ?? "",
            items.map { $0.name.lowercased() }.joined(separator: " "),
            rawText.lowercased()
        ].joined(separator: " ")

        // 餐飲關鍵字
        let foodKeywords = [
            "餐廳", "restaurant", "cafe", "咖啡", "coffee", "飲料", "drink",
            "麵", "飯", "便當", "早餐", "午餐", "晚餐", "宵夜",
            "麥當勞", "mcdonald", "肯德基", "kfc", "星巴克", "starbucks",
            "吃到飽", "火鍋", "燒肉", "焼肉", "壽司", "寿司", "拉麵", "ラーメン", "pizza", "漢堡",
            "食品", "food", "小吃", "夜市", "美食", "甜點", "dessert",
            "茶", "tea", "酒", "bar", "居酒屋", "料理", "廚房",
            "焼鳥", "うどん", "そば", "丼", "弁当", "食堂", "レストラン", "カフェ"
        ]

        // 交通關鍵字
        let transportKeywords = [
            "uber", "taxi", "計程車", "捷運", "metro", "mrt", "公車", "bus",
            "高鐵", "台鐵", "火車", "train", "機票", "flight", "航空",
            "加油", "gas", "油站", "停車", "parking", "租車", "grab",
            "悠遊卡", "一卡通", "交通", "transport"
        ]

        // 住宿關鍵字
        let accommodationKeywords = [
            "hotel", "飯店", "旅館", "民宿", "hostel", "airbnb",
            "住宿", "房間", "room", "inn", "lodge", "resort"
        ]

        // 購物關鍵字
        let shoppingKeywords = [
            "百貨", "mall", "商場", "超市", "supermarket", "便利商店",
            "7-eleven", "全家", "familymart", "萊爾富", "ok mart",
            "服飾", "衣服", "clothes", "鞋", "shoes", "包", "bag",
            "電子", "electronics", "藥妝", "屈臣氏", "康是美",
            "outlet", "shop", "store", "市場", "market"
        ]

        // 門票關鍵字
        let ticketKeywords = [
            "門票", "ticket", "入場", "admission", "博物館", "museum",
            "展覽", "exhibition", "演唱會", "concert", "表演", "show",
            "景點", "attraction", "觀光", "tour"
        ]

        // 娛樂關鍵字
        let entertainmentKeywords = [
            "電影", "cinema", "movie", "ktv", "卡拉ok", "遊戲",
            "game", "樂園", "park", "spa", "按摩", "massage",
            "健身", "gym", "運動", "sport", "夜店", "club"
        ]

        // 按優先順序檢查（依發票頻率：餐飲 > 交通 > 購物 > 門票 > 娛樂 > 住宿）
        for keyword in foodKeywords {
            if searchText.contains(keyword) { return "food" }
        }

        for keyword in transportKeywords {
            if searchText.contains(keyword) { return "transport" }
        }

        for keyword in shoppingKeywords {
            if searchText.contains(keyword) { return "shopping" }
        }

        for keyword in ticketKeywords {
            if searchText.contains(keyword) { return "tickets" }
        }

        for keyword in entertainmentKeywords {
            if searchText.contains(keyword) { return "entertainment" }
        }

        for keyword in accommodationKeywords {
            if searchText.contains(keyword) { return "accommodation" }
        }

        return nil
    }
}

enum GeminiOCRError: LocalizedError {
    case invalidImage
    case invalidURL
    case requestFailed
    case serverError(statusCode: Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return String(localized: "error.ocr.invalidImage")
        case .invalidURL:
            return String(localized: "error.ocr.invalidURL")
        case .requestFailed:
            return String(localized: "error.ocr.requestFailed")
        case .serverError(let code):
            return String(localized: "error.ocr.serverError \(code)")
        case .decodingFailed:
            return String(localized: "error.ocr.decodingFailed")
        }
    }
}
