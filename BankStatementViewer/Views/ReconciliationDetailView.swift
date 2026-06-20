import SwiftUI

struct ReconciliationDetailView: View {
    let result: ParseResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: (result.ok ?? true) ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle((result.ok ?? true) ? .green : .red)
                Text(result.displayBank)
                    .fontWeight(.semibold)
                if !result.reconciliationSummary.isEmpty {
                    Text(result.reconciliationSummary)
                        .foregroundStyle(.secondary)
                }
            }

            if checks.isEmpty {
                Text("No reconciliation checks reported.")
                    .foregroundStyle(.secondary)
            } else {
                Divider()
                ForEach(checks) { check in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: check.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(check.passed ? .green : .red)
                            .font(.body)
                        Text(check.label)
                            .font(.system(.body, design: .monospaced))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(16)
        .frame(minWidth: 360, maxWidth: 480)
    }

    private var checks: [ParseResult.ReconciliationCheck] {
        result.reconciliationChecks
    }
}
