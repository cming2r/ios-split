import Foundation

// MARK: - Participant (JSONB nested in split_trips)
struct Participant: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var isMe: Bool
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case isMe = "is_me"
        case sortOrder = "sort_order"
    }

    init(id: UUID = UUID(), name: String, isMe: Bool = false, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.isMe = isMe
        self.sortOrder = sortOrder
    }
}


// MARK: - ExpenseItemData (JSONB nested in split_expenses)
struct ExpenseItemData: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var quantity: Double
    var unitPrice: Double?
    var totalPrice: Double?
    var sortOrder: Int
    var assignedParticipantIds: [UUID]?

    enum CodingKeys: String, CodingKey {
        case id, name, quantity
        case unitPrice = "unit_price"
        case totalPrice = "total_price"
        case sortOrder = "sort_order"
        case assignedParticipantIds = "assigned_participant_ids"
    }

    init(id: UUID = UUID(), name: String, quantity: Double = 1, unitPrice: Double? = nil, totalPrice: Double? = nil, sortOrder: Int = 0, assignedParticipantIds: [UUID]? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.totalPrice = totalPrice
        self.sortOrder = sortOrder
        self.assignedParticipantIds = assignedParticipantIds
    }
}

// MARK: - SplitTrip (corresponds to split_trips table)
struct SplitTrip: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var destinationCountryCode: String
    var startDate: Date
    var endDate: Date
    var baseCurrencyCode: String
    var exchangeRate: [String: Double]
    var timeZoneIdentifier: String
    var notes: String
    var participants: [Participant]
    var deviceId: String
    var userId: UUID?
    var clientInfo: [String: String]?
    var ipAddress: String?
    var countryCode: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, notes, participants
        case destinationCountryCode = "destination_country_code"
        case startDate = "start_date"
        case endDate = "end_date"
        case baseCurrencyCode = "base_currency_code"
        case exchangeRate = "exchange_rate"
        case timeZoneIdentifier = "timezone_id"
        case deviceId = "device_id"
        case userId = "user_id"
        case clientInfo = "client_info"
        case ipAddress = "ip_address"
        case countryCode = "country_code"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        name: String,
        destinationCountryCode: String = "",
        startDate: Date = Date(),
        endDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60),
        baseCurrencyCode: String = Locale.current.currency?.identifier ?? "USD",
        exchangeRate: [String: Double] = [:],
        timeZoneIdentifier: String = TimeZone.current.identifier,
        notes: String = "",
        participants: [Participant] = [],
        deviceId: String = "",
        userId: UUID? = nil,
        clientInfo: [String: String]? = nil,
        ipAddress: String? = nil,
        countryCode: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.destinationCountryCode = destinationCountryCode
        self.startDate = startDate
        self.endDate = endDate
        self.baseCurrencyCode = baseCurrencyCode
        self.exchangeRate = exchangeRate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.notes = notes
        self.participants = participants
        self.deviceId = deviceId
        self.userId = userId
        self.clientInfo = clientInfo
        self.ipAddress = ipAddress
        self.countryCode = countryCode
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        destinationCountryCode = try container.decode(String.self, forKey: .destinationCountryCode)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        baseCurrencyCode = try container.decode(String.self, forKey: .baseCurrencyCode)
        exchangeRate = (try? container.decode([String: Double].self, forKey: .exchangeRate)) ?? [:]
        timeZoneIdentifier = try container.decode(String.self, forKey: .timeZoneIdentifier)
        notes = try container.decode(String.self, forKey: .notes)
        participants = try container.decode([Participant].self, forKey: .participants)
        deviceId = try container.decode(String.self, forKey: .deviceId)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        clientInfo = try container.decodeIfPresent([String: String].self, forKey: .clientInfo)
        ipAddress = try container.decodeIfPresent(String.self, forKey: .ipAddress)
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    // MARK: - Computed Properties

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
    }

    var sortedParticipants: [Participant] {
        participants.sorted { $0.sortOrder < $1.sortOrder }
    }

    var duration: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }

    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    func formatTime(_ date: Date, style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = style
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }

    func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        return formatter.string(from: date)
    }
}

// MARK: - SplitExpense (corresponds to split_expenses table)
struct SplitExpense: Codable, Identifiable, Hashable {
    var id: UUID
    var tripId: UUID
    var title: String
    var amount: Double
    var currencyCode: String
    var date: Date
    var category: String
    var paidById: String?
    var tags: [String]
    var items: [ExpenseItemData]
    var subtitle: String?
    var address: String?
    var isFromOCR: Bool
    var receiptImagePaths: [String]
    var notes: String
    var deviceId: String
    var clientInfo: [String: String]?
    var ipAddress: String?
    var countryCode: String?
    var createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, amount, date, items, notes, category, tags
        case tripId = "trip_id"
        case currencyCode = "currency_code"
        case paidById = "paid_by_id"
        case subtitle
        case address
        case isFromOCR = "is_from_ocr"
        case receiptImagePaths = "receipt_image_path"
        case deviceId = "device_id"
        case clientInfo = "client_info"
        case ipAddress = "ip_address"
        case countryCode = "country_code"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        tripId: UUID,
        title: String,
        amount: Double,
        currencyCode: String = Locale.current.currency?.identifier ?? "USD",
        date: Date = Date(),
        category: String = "other",
        paidById: String? = nil,
        tags: [String] = [],
        items: [ExpenseItemData] = [],
        subtitle: String? = nil,
        address: String? = nil,
        isFromOCR: Bool = false,
        receiptImagePaths: [String] = [],
        notes: String = "",
        deviceId: String = "",
        clientInfo: [String: String]? = nil,
        ipAddress: String? = nil,
        countryCode: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.tripId = tripId
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.date = date
        self.category = category
        self.paidById = paidById
        self.tags = tags
        self.items = items
        self.subtitle = subtitle
        self.address = address
        self.isFromOCR = isFromOCR
        self.receiptImagePaths = receiptImagePaths
        self.notes = notes
        self.deviceId = deviceId
        self.clientInfo = clientInfo
        self.ipAddress = ipAddress
        self.countryCode = countryCode
        self.createdAt = createdAt
    }

    // MARK: - Computed Properties

    func amountInBaseCurrency(from trip: SplitTrip) -> Double {
        if currencyCode == trip.baseCurrencyCode {
            return amount
        }
        if let rate = trip.exchangeRate[currencyCode] {
            return amount * rate
        }
        return amount
    }

    /// Get category from static data
    var staticCategory: StaticCategory? {
        StaticCategory.find(byId: category)
    }

    /// Get all trip participants for this expense
    func participants(from trip: SplitTrip) -> [Participant] {
        trip.sortedParticipants
    }

    /// Per-person amount in base currency
    func amountPerPerson(from trip: SplitTrip) -> Double {
        let parts = participants(from: trip)
        let base = amountInBaseCurrency(from: trip)
        guard !parts.isEmpty else { return base }
        return base / Double(parts.count)
    }

    /// Get the payer participant from the trip
    func paidBy(from trip: SplitTrip) -> Participant? {
        guard let pid = paidById,
              let payerUUID = UUID(uuidString: pid) else { return nil }
        return trip.participants.first { $0.id == payerUUID }
    }
}
