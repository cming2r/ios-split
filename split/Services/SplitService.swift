import Foundation
import Supabase

class SplitService {
    static let shared = SplitService()

    private let client: SupabaseClient
    private let tripsTable = "split_trips"
    private let expensesTable = "split_expenses"

    private init() {
        // Reuse the same Supabase client from FeedbackService
        self.client = FeedbackService.shared.client
    }

    // MARK: - Trip CRUD

    func fetchTrips() async throws -> [SplitTrip] {
        let authUserId = await AuthService.shared.userId
        var query = client.from(tripsTable).select()

        if let userId = authUserId {
            query = query.eq("user_id", value: userId)
        } else {
            let deviceId = FeedbackService.getDeviceId()
            query = query.eq("device_id", value: deviceId)
                .is("user_id", value: nil)
        }

        let response = try await query
            .order("start_date", ascending: false)
            .execute()

        return try Self.decode([SplitTrip].self, from: response.data)
    }

    func createTrip(_ trip: SplitTrip) async throws -> SplitTrip {
        var tripToCreate = trip
        tripToCreate.deviceId = FeedbackService.getDeviceId()
        tripToCreate.userId = await AuthService.shared.userId
        tripToCreate.clientInfo = FeedbackService.buildClientInfo()
        tripToCreate.countryCode = FeedbackService.getCountryCode()
        tripToCreate.ipAddress = await FeedbackService.fetchIPAddress()

        let response = try await client
            .from(tripsTable)
            .insert(tripToCreate)
            .select()
            .single()
            .execute()

        return try Self.decode(SplitTrip.self, from: response.data)
    }

    func updateTrip(_ trip: SplitTrip) async throws -> SplitTrip {
        let response = try await client
            .from(tripsTable)
            .update(trip)
            .eq("id", value: trip.id)
            .select()
            .single()
            .execute()

        return try Self.decode(SplitTrip.self, from: response.data)
    }

    func deleteTrip(id: UUID) async throws {
        // Fetch expenses to collect image URLs before deletion
        let expenses = try await fetchExpenses(tripId: id)
        let imageUrls = expenses.flatMap { $0.receiptImagePaths }

        // Delete all expenses for this trip first
        _ = try await client
            .from(expensesTable)
            .delete()
            .eq("trip_id", value: id)
            .execute()

        _ = try await client
            .from(tripsTable)
            .delete()
            .eq("id", value: id)
            .execute()

        // Clean up R2 images
        if !imageUrls.isEmpty {
            await Self.deleteR2Images(imageUrls)
        }
    }

    // MARK: - Expense CRUD

    func fetchExpenses(tripId: UUID) async throws -> [SplitExpense] {
        let response = try await client
            .from(expensesTable)
            .select()
            .eq("trip_id", value: tripId)
            .order("date", ascending: false)
            .execute()

        return try Self.decode([SplitExpense].self, from: response.data)
    }

    func createExpense(_ expense: SplitExpense) async throws -> SplitExpense {
        var expenseToCreate = expense
        expenseToCreate.deviceId = FeedbackService.getDeviceId()
        expenseToCreate.clientInfo = FeedbackService.buildClientInfo()
        expenseToCreate.countryCode = FeedbackService.getCountryCode()
        expenseToCreate.ipAddress = await FeedbackService.fetchIPAddress()

        let response = try await client
            .from(expensesTable)
            .insert(expenseToCreate)
            .select()
            .single()
            .execute()

        return try Self.decode(SplitExpense.self, from: response.data)
    }

    func updateExpense(_ expense: SplitExpense) async throws -> SplitExpense {
        let response = try await client
            .from(expensesTable)
            .update(expense)
            .eq("id", value: expense.id)
            .select()
            .single()
            .execute()

        return try Self.decode(SplitExpense.self, from: response.data)
    }

    func deleteExpense(id: UUID) async throws {
        // Fetch expense to collect image URLs before deletion
        let response = try? await client
            .from(expensesTable)
            .select()
            .eq("id", value: id)
            .single()
            .execute()
        let imageUrls: [String] = {
            guard let data = response?.data,
                  let expense = try? Self.decode(SplitExpense.self, from: data) else { return [] }
            return expense.receiptImagePaths
        }()

        _ = try await client
            .from(expensesTable)
            .delete()
            .eq("id", value: id)
            .execute()

        // Clean up R2 images
        if !imageUrls.isEmpty {
            await Self.deleteR2Images(imageUrls)
        }
    }

    // MARK: - R2 Image Cleanup

    static func deleteR2Images(_ urls: [String]) async {
        let fileNames = urls.compactMap { URL(string: $0)?.lastPathComponent }
        guard !fileNames.isEmpty,
              let apiUrl = URL(string: "https://vvmg.cc/api/split-scan") else { return }

        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "action": "delete-images",
            "file_names": fileNames
        ])
        request.timeoutInterval = 30
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Date Decoding (reuse FeedbackService pattern)

    static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        return try decoder.decode(type, from: data)
    }

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
