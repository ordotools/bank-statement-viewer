import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var pdfURL: URL?
    @State private var parseResult: ParseResult?
    @State private var selectedTransactionID: Transaction.ID?
    @State private var isParsing = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var showReconciliationDetail = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            mainContent
        }
        .frame(minWidth: 900, minHeight: 600)
        .onDrop(of: [.pdf, .fileURL], isTargeted: nil) { providers in
            handleWindowDrop(providers: providers)
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onChange(of: searchText) { _, _ in
            reconcileSelectionWithFilter()
        }
        .focusedSceneValue(\.appActions, AppActions(
            openPDF: openPDF,
            copyRow: copyRow,
            copyAll: copyAll,
            exportCSV: exportTransactions,
            focusSearch: { searchFocused = true }
        ))
    }

    private var filteredTransactions: [Transaction] {
        guard let txns = parseResult?.transactions else { return [] }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return txns }
        let lowered = query.lowercased()
        return txns.filter { txn in
            txn.date.lowercased().contains(lowered)
                || txn.description.lowercased().contains(lowered)
                || txn.formattedAmount.contains(query)
                || txn.formattedBalance.contains(query)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button("Open PDF…") { openPDF() }
            Button("Copy Row") { copyRow() }
                .disabled(selectedTransactionID == nil)
            Button("Copy All") { copyAll() }
                .disabled(filteredTransactions.isEmpty)
            Button("Export…") { exportTransactions() }
                .disabled(parseResult?.transactions?.isEmpty != false)

            Spacer()

            if isParsing {
                ProgressView()
                    .controlSize(.small)
                Text("Parsing…")
                    .foregroundStyle(.secondary)
            } else if let parseResult, parseResult.isSuccess {
                reconciliationBadge(for: parseResult)
            }

            if let pdfURL {
                Text(pdfURL.lastPathComponent)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var mainContent: some View {
        if pdfURL == nil && !isParsing {
            DropTargetView { url in loadPDF(url) }
                .padding(40)
        } else {
            HSplitView {
                PDFPreviewView(url: pdfURL)
                    .frame(minWidth: 320)
                rightPane
                    .frame(minWidth: 360)
            }
        }
    }

    @ViewBuilder
    private var rightPane: some View {
        if let errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if isParsing {
            ProgressView("Extracting transactions…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let parseResult, !filteredTransactions.isEmpty {
            VStack(spacing: 0) {
                searchBar
                Divider()
                TransactionTableView(
                    transactions: filteredTransactions,
                    total: filteredTotal(for: parseResult),
                    selection: $selectedTransactionID
                )
            }
        } else if parseResult?.transactions?.isEmpty == false {
            VStack(spacing: 12) {
                searchBar
                Text("No matching transactions")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Text("No transactions")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search transactions…", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .focused($searchFocused)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            if let total = parseResult?.transactions?.count, total > 0 {
                Text("\(filteredTransactions.count) of \(total)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func reconciliationBadge(for result: ParseResult) -> some View {
        let ok = result.ok ?? true
        let hasDetail = !result.reconciliationChecks.isEmpty || result.ok != nil

        Button {
            showReconciliationDetail = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: ok ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(ok ? .green : .red)
                Text(result.displayBank)
                    .fontWeight(.medium)
                if !result.reconciliationSummary.isEmpty {
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(result.reconciliationSummary)
                        .foregroundStyle(.secondary)
                }
                if hasDetail {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showReconciliationDetail) {
            ReconciliationDetailView(result: result)
        }
        .disabled(!hasDetail)
    }

    private func filteredTotal(for result: ParseResult) -> Double? {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return result.total
        }
        return filteredTransactions.reduce(0) { $0 + $1.amount }
    }

    private func openPDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        loadPDF(url)
    }

    private func loadPDF(_ url: URL) {
        pdfURL = url
        parseResult = nil
        selectedTransactionID = nil
        errorMessage = nil
        searchText = ""
        isParsing = true

        Task {
            do {
                let result = try await ParserService.parse(pdfURL: url)
                parseResult = result
                selectedTransactionID = result.transactions?.first?.id
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
                parseResult = nil
            }
            isParsing = false
        }
    }

    private func handleWindowDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension.lowercased() == "pdf"
            else { return }
            DispatchQueue.main.async { loadPDF(url) }
        }
        return true
    }

    private func copyRow() {
        guard let id = selectedTransactionID,
              let txn = filteredTransactions.first(where: { $0.id == id })
        else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(txn.tsvLine(), forType: .string)
    }

    private func copyAll() {
        let txns = filteredTransactions
        guard !txns.isEmpty else { return }
        let header = ["date", "description", "amount", "balance"].joined(separator: "\t")
        let body = txns.map { $0.tsvLine() }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString([header, body].joined(separator: "\n"), forType: .string)
    }

    private func exportTransactions() {
        guard let txns = parseResult?.transactions, !txns.isEmpty else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText, .tabSeparatedText]
        panel.allowsOtherFileTypes = false
        panel.nameFieldStringValue = defaultExportName()
        panel.message = "Export all transactions"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            if url.pathExtension.lowercased() == "tsv" {
                try TransactionExport.writeTSV(transactions: txns, to: url)
            } else {
                try TransactionExport.writeCSV(transactions: txns, to: url)
            }
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func defaultExportName() -> String {
        if let pdfURL {
            return "\(pdfURL.deletingPathExtension().lastPathComponent)-transactions.csv"
        }
        return "transactions.csv"
    }

    private func moveSelection(by delta: Int) {
        let txns = filteredTransactions
        guard !txns.isEmpty else { return }

        if let id = selectedTransactionID,
           let index = txns.firstIndex(where: { $0.id == id }) {
            let newIndex = min(max(index + delta, 0), txns.count - 1)
            selectedTransactionID = txns[newIndex].id
        } else {
            selectedTransactionID = txns.first?.id
        }
    }

    private func reconcileSelectionWithFilter() {
        let txns = filteredTransactions
        guard !txns.isEmpty else {
            selectedTransactionID = nil
            return
        }
        if let id = selectedTransactionID,
           txns.contains(where: { $0.id == id }) {
            return
        }
        selectedTransactionID = txns.first?.id
    }
}

#Preview {
    ContentView()
}
