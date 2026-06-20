import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var pdfURL: URL?
    @State private var parseResult: ParseResult?
    @State private var selectedTransactionID: Transaction.ID?
    @State private var isParsing = false
    @State private var errorMessage: String?

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
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button("Open PDF…") { openPDF() }
            Button("Copy Row") { copyRow() }
                .disabled(selectedTransactionID == nil)
            Button("Copy All") { copyAll() }
                .disabled(parseResult?.transactions?.isEmpty != false)

            Spacer()

            if isParsing {
                ProgressView()
                    .controlSize(.small)
                Text("Parsing…")
                    .foregroundStyle(.secondary)
            } else if let parseResult, parseResult.isSuccess {
                statusBadge(for: parseResult)
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
        } else if let txns = parseResult?.transactions, !txns.isEmpty {
            TransactionTableView(
                transactions: txns,
                selection: $selectedTransactionID
            )
        } else {
            Text("No transactions")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func statusBadge(for result: ParseResult) -> some View {
        let ok = result.ok ?? true
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
        }
        .font(.subheadline)
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
              let txn = parseResult?.transactions?.first(where: { $0.id == id })
        else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(txn.tsvLine(), forType: .string)
    }

    private func copyAll() {
        guard let txns = parseResult?.transactions, !txns.isEmpty else { return }
        let header = ["date", "description", "amount", "balance"].joined(separator: "\t")
        let body = txns.map { $0.tsvLine() }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString([header, body].joined(separator: "\n"), forType: .string)
    }
}

#Preview {
    ContentView()
}
