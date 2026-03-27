import Foundation

/// 結算結果 - 每個人的收支狀況
struct ParticipantBalance: Identifiable {
    let id: UUID
    let participant: Participant
    let totalPaid: Double
    let totalOwed: Double
    var balance: Double { totalPaid - totalOwed }
}

/// 建議的轉帳
struct SuggestedTransfer: Identifiable {
    let id = UUID()
    let from: Participant
    let to: Participant
    let amount: Double
}

/// 分帳計算服務
class SettlementService {

    /// 計算每個人的收支餘額
    static func calculateBalances(for expenses: [SplitExpense], trip: SplitTrip) -> [ParticipantBalance] {
        let participants = trip.sortedParticipants
        let validParticipantIds = Set(participants.map { $0.id })
        var paidAmounts: [UUID: Double] = [:]
        var owedAmounts: [UUID: Double] = [:]

        for participant in participants {
            paidAmounts[participant.id] = 0
            owedAmounts[participant.id] = 0
        }

        for expense in expenses {
            let baseAmount = expense.amountInBaseCurrency(from: trip)

            // 付款人付的金額
            if let payerIdStr = expense.paidById,
               let payerId = UUID(uuidString: payerIdStr),
               validParticipantIds.contains(payerId) {
                paidAmounts[payerId, default: 0] += baseAmount
            }

            // 獲取全體參與者並計算應付金額
            let expenseParticipants = expense.participants(from: trip).filter { validParticipantIds.contains($0.id) }
            if !expenseParticipants.isEmpty {
                let hasItemAssignments = !expense.items.isEmpty && expense.items.contains { $0.assignedParticipantIds != nil && !($0.assignedParticipantIds!.isEmpty) }

                if hasItemAssignments {
                    // Item-level 分帳模式
                    let rate: Double = {
                        if expense.currencyCode == trip.baseCurrencyCode { return 1.0 }
                        return trip.exchangeRate[expense.currencyCode] ?? 1.0
                    }()
                    var itemsTotal: Double = 0
                    for item in expense.items {
                        let itemAmount = (item.totalPrice ?? item.unitPrice ?? 0) * rate
                        itemsTotal += itemAmount
                        let assignees: [UUID]
                        if let ids = item.assignedParticipantIds, !ids.isEmpty {
                            assignees = ids.filter { validParticipantIds.contains($0) }
                        } else {
                            assignees = expenseParticipants.map { $0.id }
                        }
                        guard !assignees.isEmpty else { continue }
                        let perPerson = itemAmount / Double(assignees.count)
                        for id in assignees {
                            owedAmounts[id, default: 0] += perPerson
                        }
                    }
                    // 差額（稅/服務費等）由全體均分
                    let remainder = baseAmount - itemsTotal
                    if abs(remainder) > 0.01 {
                        let perPerson = remainder / Double(expenseParticipants.count)
                        for participant in expenseParticipants {
                            owedAmounts[participant.id, default: 0] += perPerson
                        }
                    }
                } else {
                    // 原本邏輯：全額均分
                    let perPersonAmount = baseAmount / Double(expenseParticipants.count)
                    for participant in expenseParticipants {
                        owedAmounts[participant.id, default: 0] += perPersonAmount
                    }
                }
            }
        }

        return participants.compactMap { participant in
            let paid = paidAmounts[participant.id] ?? 0
            let owed = owedAmounts[participant.id] ?? 0
            guard paid > 0 || owed > 0 else { return nil }
            return ParticipantBalance(id: participant.id, participant: participant, totalPaid: paid, totalOwed: owed)
        }
    }

    /// 計算建議的轉帳方式（最少交易次數）
    static func calculateSuggestedTransfers(balances: [ParticipantBalance]) -> [SuggestedTransfer] {
        var transfers: [SuggestedTransfer] = []

        var debtors = balances.filter { $0.balance < -0.01 }
            .map { (participant: $0.participant, amount: -$0.balance) }
            .sorted { $0.amount > $1.amount }

        var creditors = balances.filter { $0.balance > 0.01 }
            .map { (participant: $0.participant, amount: $0.balance) }
            .sorted { $0.amount > $1.amount }

        while !debtors.isEmpty && !creditors.isEmpty {
            var debtor = debtors.removeFirst()
            var creditor = creditors.removeFirst()

            let transferAmount = min(debtor.amount, creditor.amount)

            if transferAmount > 0.01 {
                transfers.append(SuggestedTransfer(
                    from: debtor.participant,
                    to: creditor.participant,
                    amount: transferAmount
                ))
            }

            debtor.amount -= transferAmount
            creditor.amount -= transferAmount

            if debtor.amount > 0.01 {
                debtors.insert(debtor, at: 0)
            }
            if creditor.amount > 0.01 {
                creditors.insert(creditor, at: 0)
            }
        }

        return transfers
    }
}
