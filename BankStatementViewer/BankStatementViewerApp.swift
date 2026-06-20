import SwiftUI

@main
struct BankStatementViewerApp: App {
    @FocusedValue(\.appActions) private var appActions

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandGroup(after: .importExport) {
                Button("Open PDF…") {
                    appActions?.openPDF?()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Export…") {
                    appActions?.exportCSV?()
                }
                .keyboardShortcut("e", modifiers: .command)
            }

            CommandGroup(replacing: .pasteboard) {
                Button("Copy Row") {
                    appActions?.copyRow?()
                }
                .keyboardShortcut("c", modifiers: .command)

                Button("Copy All") {
                    appActions?.copyAll?()
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }

            CommandGroup(after: .textEditing) {
                Button("Search Transactions") {
                    appActions?.focusSearch?()
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
}
