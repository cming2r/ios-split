import Foundation

class SampleDataService {
    static let shared = SampleDataService()

    private static let dismissedKey = "hasDismissedSampleData"
    private static let firstLaunchKey = "sampleDataFirstLaunchDate"
    private static let autoExpireDays = 7

    private init() {
        // 首次啟動時記錄日期
        if UserDefaults.standard.object(forKey: Self.firstLaunchKey) == nil {
            UserDefaults.standard.set(Date(), forKey: Self.firstLaunchKey)
        }
    }

    var hasDismissed: Bool {
        get {
            if UserDefaults.standard.bool(forKey: Self.dismissedKey) {
                return true
            }
            // 超過 7 天自動移除
            if let firstLaunch = UserDefaults.standard.object(forKey: Self.firstLaunchKey) as? Date {
                let days = Calendar.current.dateComponents([.day], from: firstLaunch, to: Date()).day ?? 0
                if days >= Self.autoExpireDays {
                    UserDefaults.standard.set(true, forKey: Self.dismissedKey)
                    return true
                }
            }
            return false
        }
        set { UserDefaults.standard.set(newValue, forKey: Self.dismissedKey) }
    }

    func dismiss() {
        hasDismissed = true
    }

    // MARK: - Sample Trip (local only)

    private(set) lazy var sampleTrip: SplitTrip = {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .day, value: -8, to: Date()) ?? Date()

        return SplitTrip(
            id: Self.sampleTripId,
            name: String(localized: "sample.trip.name"),
            destinationCountryCode: "JP",
            startDate: startDate,
            endDate: endDate,
            baseCurrencyCode: "TWD",
            exchangeRate: ["JPY": 0.215],
            timeZoneIdentifier: "Asia/Tokyo",
            notes: "",
            participants: [
                Participant(id: Self.meId, name: String(localized: "sample.participant.me"), isMe: true, sortOrder: 0),
                Participant(id: Self.friendAId, name: String(localized: "sample.participant.friendA"), isMe: false, sortOrder: 1),
                Participant(id: Self.friendBId, name: String(localized: "sample.participant.friendB"), isMe: false, sortOrder: 2),
            ]
        )
    }()

    private(set) lazy var sampleExpenses: [SplitExpense] = {
        let calendar = Calendar.current
        let day1 = sampleTrip.startDate
        let day2 = calendar.date(byAdding: .day, value: 1, to: day1)!
        let day3 = calendar.date(byAdding: .day, value: 2, to: day1)!
        let tripId = Self.sampleTripId

        return [
            // Day 1
            SplitExpense(
                tripId: tripId,
                title: String(localized: "sample.expense.ramen"),
                amount: 3600,
                currencyCode: "JPY",
                date: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: day1)!,
                category: "food",
                paidById: Self.meId.uuidString,
                items: [
                    ExpenseItemData(name: String(localized: "sample.item.tonkotsuRamen"), quantity: 2, unitPrice: 1200, totalPrice: 2400, sortOrder: 0, assignedParticipantIds: [Self.meId, Self.friendAId]),
                    ExpenseItemData(name: String(localized: "sample.item.misoRamen"), quantity: 1, unitPrice: 1200, totalPrice: 1200, sortOrder: 1, assignedParticipantIds: [Self.friendBId]),
                ],
                subtitle: String(localized: "sample.expense.ramen.subtitle")
            ),
            SplitExpense(
                tripId: tripId,
                title: String(localized: "sample.expense.subway"),
                amount: 900,
                currencyCode: "JPY",
                date: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day1)!,
                category: "transport",
                paidById: Self.friendAId.uuidString
            ),
            SplitExpense(
                tripId: tripId,
                title: String(localized: "sample.expense.temple"),
                amount: 1500,
                currencyCode: "JPY",
                date: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: day1)!,
                category: "tickets",
                paidById: Self.meId.uuidString,
                items: [
                    ExpenseItemData(name: String(localized: "sample.item.admissionTicket"), quantity: 3, unitPrice: 500, totalPrice: 1500, sortOrder: 0, assignedParticipantIds: [Self.meId, Self.friendAId, Self.friendBId]),
                ]
            ),
            // Day 2
            SplitExpense(
                tripId: tripId,
                title: String(localized: "sample.expense.sushi"),
                amount: 8400,
                currencyCode: "JPY",
                date: calendar.date(bySettingHour: 19, minute: 0, second: 0, of: day2)!,
                category: "food",
                paidById: Self.friendBId.uuidString,
                items: [
                    ExpenseItemData(name: String(localized: "sample.item.sushiSet"), quantity: 3, unitPrice: 2800, totalPrice: 8400, sortOrder: 0, assignedParticipantIds: [Self.meId, Self.friendAId, Self.friendBId]),
                ],
                subtitle: String(localized: "sample.expense.sushi.subtitle")
            ),
            SplitExpense(
                tripId: tripId,
                title: String(localized: "sample.expense.shopping"),
                amount: 5200,
                currencyCode: "JPY",
                date: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: day2)!,
                category: "shopping",
                paidById: Self.meId.uuidString,
                items: [
                    ExpenseItemData(name: String(localized: "sample.item.snacks"), quantity: 1, unitPrice: 2200, totalPrice: 2200, sortOrder: 0, assignedParticipantIds: [Self.meId, Self.friendAId, Self.friendBId]),
                    ExpenseItemData(name: String(localized: "sample.item.souvenir"), quantity: 1, unitPrice: 3000, totalPrice: 3000, sortOrder: 1, assignedParticipantIds: [Self.meId]),
                ],
                subtitle: String(localized: "sample.expense.shopping.subtitle")
            ),
            // Day 3
            SplitExpense(
                tripId: tripId,
                title: String(localized: "sample.expense.hotel"),
                amount: 36000,
                currencyCode: "JPY",
                date: calendar.date(bySettingHour: 22, minute: 0, second: 0, of: day3)!,
                category: "accommodation",
                paidById: Self.friendAId.uuidString,
                items: [
                    ExpenseItemData(name: String(localized: "sample.item.hotelRoom"), quantity: 3, unitPrice: 12000, totalPrice: 36000, sortOrder: 0, assignedParticipantIds: [Self.meId, Self.friendAId, Self.friendBId]),
                ],
                subtitle: String(localized: "sample.expense.hotel.subtitle")
            ),
            SplitExpense(
                tripId: tripId,
                title: String(localized: "sample.expense.taxi"),
                amount: 2800,
                currencyCode: "JPY",
                date: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day3)!,
                category: "transport",
                paidById: Self.meId.uuidString
            ),
        ]
    }()

    // MARK: - Fixed IDs

    static let sampleTripId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private static let meId = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    private static let friendAId = UUID(uuidString: "00000000-0000-0000-0000-000000000011")!
    private static let friendBId = UUID(uuidString: "00000000-0000-0000-0000-000000000012")!

    static func isSampleTrip(_ tripId: UUID) -> Bool {
        tripId == sampleTripId
    }
}
