import Foundation
import UIKit
import Supabase

class FeedbackService {
    static let shared = FeedbackService()

    let client: SupabaseClient
    private let tableName = "contact_messages"

    private init() {
        guard let path = Bundle.main.path(forResource: "APICredentials", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let supabase = dict["Supabase"] as? [String: String],
              let urlString = supabase["URL"],
              let url = URL(string: urlString),
              let key = supabase["AnonKey"] else {
            fatalError("Missing APICredentials.plist or Supabase config")
        }
        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    // MARK: - Create Contact Message
    func createContactMessage(_ message: ContactMessage) async throws -> ContactMessage {
        let response = try await client
            .from(tableName)
            .insert(message)
            .select()
            .single()
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Self.dateDecodingStrategy
        return try decoder.decode(ContactMessage.self, from: response.data)
    }

    // MARK: - Fetch User Messages
    func fetchUserMessages(deviceId: String) async throws -> [ContactMessage] {
        let response = try await client
            .from(tableName)
            .select()
            .eq("device_id", value: deviceId)
            .eq("app_from", value: "WhoSplit")
            .order("created_at", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = Self.dateDecodingStrategy
        return try decoder.decode([ContactMessage].self, from: response.data)
    }

    // MARK: - Delete Message
    func deleteMessage(id: UUID) async throws {
        _ = try await client
            .from(tableName)
            .delete()
            .eq("id", value: id)
            .execute()
    }

    // MARK: - Device Helpers
    static func getDeviceId() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }

    static func buildClientInfo() -> [String: String] {
        let device = UIDevice.current
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return [
            "os": "iOS \(device.systemVersion)",
            "device": getDeviceModel(),
            "app_version": "\(version) (\(build))"
        ]
    }

    private static func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier.isEmpty ? UIDevice.current.model : identifier
    }

    static func getCountryCode() -> String {
        Locale.current.region?.identifier ?? "Unknown"
    }

    // MARK: - IP Address
    static func fetchIPAddress() async -> String? {
        guard let url = URL(string: "https://api.ipify.org?format=json") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: String] {
                return json["ip"]
            }
        } catch {
            print("Failed to fetch IP: \(error.localizedDescription)")
        }
        return nil
    }

    // MARK: - Date Decoding
    private static var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy {
        .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatter = DateFormatter()
            formatter.timeZone = TimeZone(secondsFromGMT: 0)

            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS+00:00",
                "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss+00:00",
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss"
            ]

            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot parse date: \(dateString)"
            )
        }
    }
}
