import Foundation

enum TransactionExport {
    private static let csvHeader = "date,description,amount,balance"
    private static let tsvHeader = ["date", "description", "amount", "balance"].joined(separator: "\t")

    static func csv(from transactions: [Transaction]) -> String {
        let rows = transactions.map(csvLine)
        return ([csvHeader] + rows).joined(separator: "\n")
    }

    static func tsv(from transactions: [Transaction]) -> String {
        let rows = transactions.map { $0.tsvLine() }
        return ([tsvHeader] + rows).joined(separator: "\n")
    }

    static func writeCSV(transactions: [Transaction], to url: URL) throws {
        try csv(from: transactions).write(to: url, atomically: true, encoding: .utf8)
    }

    static func writeTSV(transactions: [Transaction], to url: URL) throws {
        try tsv(from: transactions).write(to: url, atomically: true, encoding: .utf8)
    }

    private static func csvLine(_ txn: Transaction) -> String {
        let balance = txn.balance.map { String(format: "%.2f", $0) } ?? ""
        return [
            csvField(txn.date),
            csvField(txn.description),
            txn.formattedAmount,
            balance,
        ].joined(separator: ",")
    }

    private static func csvField(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }
}
