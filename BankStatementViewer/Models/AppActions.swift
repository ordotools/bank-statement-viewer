import SwiftUI

struct AppActions {
    var openPDF: (() -> Void)?
    var copyRow: (() -> Void)?
    var copyAll: (() -> Void)?
    var exportCSV: (() -> Void)?
    var focusSearch: (() -> Void)?
}

private struct AppActionsKey: FocusedValueKey {
    typealias Value = AppActions
    static let defaultValue: AppActions? = nil
}

extension FocusedValues {
    var appActions: AppActions? {
        get { self[AppActionsKey.self] }
        set { self[AppActionsKey.self] = newValue }
    }
}
