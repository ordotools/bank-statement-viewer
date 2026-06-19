import SwiftUI

struct TransactionTableView: View {
    let transactions: [Transaction]
    @Binding var selection: Transaction.ID?

    var body: some View {
        Table(transactions, selection: $selection) {
            TableColumn("Date") { txn in
                Text(txn.date)
                    .font(.system(.body, design: .monospaced))
            }
            .width(min: 90, ideal: 100)

            TableColumn("Description") { txn in
                Text(txn.description)
                    .lineLimit(2)
            }
            .width(min: 160, ideal: 280)

            TableColumn("Amount") { txn in
                Text(txn.formattedAmount)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(txn.amount < 0 ? .red : .green)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 80, ideal: 100)

            TableColumn("Balance") { txn in
                Text(txn.formattedBalance)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(min: 80, ideal: 100)
        }
    }
}
