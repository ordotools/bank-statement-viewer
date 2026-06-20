import SwiftUI

struct TransactionTableView: View {
    let transactions: [Transaction]
    let total: Double?
    @Binding var selection: Transaction.ID?

    private var displayTotal: Double {
        total ?? transactions.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 0) {
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

            Divider()

            HStack(spacing: 0) {
                Text("Total")
                    .fontWeight(.semibold)
                    .frame(width: 100, alignment: .leading)
                    .padding(.leading, 8)

                Spacer(minLength: 160)

                Text(String(format: "%.2f", displayTotal))
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(displayTotal < 0 ? .red : .green)
                    .frame(width: 100, alignment: .trailing)

                Text("")
                    .frame(width: 100)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(nsColor: .controlBackgroundColor))
        }
    }
}
