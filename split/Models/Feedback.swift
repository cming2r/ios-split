import Foundation

// MARK: - Feedback Category
enum FeedbackCategory: String, CaseIterable, Codable {
    case bug = "bug"
    case feature = "feature"
    case question = "question"
    case other = "other"

    var displayName: String {
        switch self {
        case .bug: return String(localized: "feedback.category.bug")
        case .feature: return String(localized: "feedback.category.feature")
        case .question: return String(localized: "feedback.category.question")
        case .other: return String(localized: "feedback.category.other")
        }
    }
}

// MARK: - Feedback Status
enum FeedbackStatus: String, Codable {
    case pending = "pending"
    case read = "read"
    case replied = "replied"
    case closed = "closed"

    var displayName: String {
        switch self {
        case .pending: return String(localized: "feedback.status.pending")
        case .read: return String(localized: "feedback.status.read")
        case .replied: return String(localized: "feedback.status.replied")
        case .closed: return String(localized: "feedback.status.closed")
        }
    }
}

// MARK: - Contact Message
struct ContactMessage: Identifiable, Codable {
    let id: UUID
    let contactEmail: String?
    let category: FeedbackCategory
    let subject: String
    let message: String
    let deviceId: String
    let appFrom: String
    let notes: String?
    let clientInfo: [String: String]?
    let ipAddress: String?
    let countryCode: String?
    let status: FeedbackStatus
    let adminNotes: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case contactEmail = "contact_email"
        case category
        case subject
        case message
        case deviceId = "device_id"
        case appFrom = "app_from"
        case notes
        case clientInfo = "client_info"
        case ipAddress = "ip_address"
        case countryCode = "country_code"
        case status
        case adminNotes = "admin_notes"
        case createdAt = "created_at"
    }

    init(
        id: UUID = UUID(),
        contactEmail: String? = nil,
        category: FeedbackCategory,
        subject: String,
        message: String,
        deviceId: String,
        appFrom: String = "WhoSplit",
        notes: String? = nil,
        clientInfo: [String: String]? = nil,
        ipAddress: String? = nil,
        countryCode: String? = nil,
        status: FeedbackStatus = .pending,
        adminNotes: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.contactEmail = contactEmail
        self.category = category
        self.subject = subject
        self.message = message
        self.deviceId = deviceId
        self.appFrom = appFrom
        self.notes = notes
        self.clientInfo = clientInfo
        self.ipAddress = ipAddress
        self.countryCode = countryCode
        self.status = status
        self.adminNotes = adminNotes
        self.createdAt = createdAt
    }
}
