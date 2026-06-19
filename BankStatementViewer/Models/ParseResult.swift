import Foundation

struct Transaction: Codable, Identifiable, Hashable {
    let date: String
    let description: String
    let amount: Double
    let balance: Double?

    var id: String { "\(date)|\(description)|\(amount)" }

    var formattedAmount: String {
        String(format: "%.2f", amount)
    }

    var formattedBalance: String {
        guard let balance else { return "" }
        return String(format: "%.2f", balance)
    }

    func tsvLine(includeBalance: Bool = true) -> String {
        if includeBalance {
            return [date, description, formattedAmount, formattedBalance].joined(separator: "\t")
        }
        return [date, description, formattedAmount].joined(separator: "\t")
    }
}

struct ParseResult: Codable {
    let bank: String?
    let ok: Bool?
    let checks: [String]?
    let transactions: [Transaction]?
    let total: Double?
    let error: String?
    let message: String?

    var isSuccess: Bool { error == nil && transactions != nil }

    var displayBank: String {
        bank ?? "Generic parser"
    }

    var reconciliationSummary: String {
        guard let checks, !checks.isEmpty else { return ok == true ? "Reconciliation passed" : "" }
        let passed = checks.filter { $0.hasPrefix("PASS") }.count
        return "\(passed)/\(checks.count) checks passed"
    }
}

enum ParserError: LocalizedError {
    case missingBinary
    case processFailed(code: Int32, message: String)
    case invalidOutput(String)
    case decodeFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingBinary:
            return "Parser binary not found. Run the bundle-parser build script for Release, or set BANKPARSE_ROOT for Debug."
        case let .processFailed(code, message):
            return "Parser exited with code \(code): \(message)"
        case let .invalidOutput(detail):
            return "Parser returned no output: \(detail)"
        case let .decodeFailed(detail):
            return "Could not decode parser output: \(detail)"
        }
    }
}
