# Bank Statement Viewer

macOS SwiftUI app for previewing bank statement PDFs alongside parsed transactions.

Uses [bank-statement-parser](Vendor/bank-statement-parser) via subprocess.

## Requirements

- macOS 14+
- Xcode 15+
- Python 3.11+ (Debug: local venv in submodule)

## Setup

```bash
git clone <this-repo>
cd bank-statement-viewer
git submodule update --init --recursive
cd Vendor/bank-statement-parser
python3 -m venv .venv && source .venv/bin/activate
pip install -e ".[dev]"
```

Open `BankStatementViewer.xcodeproj` in Xcode.

The shared scheme sets `BANKPARSE_ROOT=$(SRCROOT)/Vendor/bank-statement-parser` for Debug builds.

## Usage

- Drag and drop a PDF, or use **Open PDF…**
- Left pane: PDF preview (PDFKit)
- Right pane: parsed transactions
- **Copy Row** / **Copy All** copies TSV to clipboard

## Build

- **Debug**: uses submodule `.venv/bin/python -m bankparse --json`
- **Release**: Run Script bundles PyInstaller binary into `Contents/Resources/bin/bankparse`

```bash
xcodebuild -scheme BankStatementViewer -configuration Release build
```

First Release build installs PyInstaller and may take several minutes.

## Distribution

```bash
./Scripts/notarize.sh build/Release/BankStatementViewer.app
```

Set `SIGNING_IDENTITY`, `APPLE_TEAM_ID`, and `NOTARY_PROFILE` as needed. See script comments.

## Limitations

- Text-layer PDFs only (no OCR for scanned statements)
- Side-by-side view is visual; parser output is not linked to PDF coordinates

## Troubleshooting / Debug console

When running from Xcode (Debug), the console may show messages that look alarming but are usually harmless:

| Message | Meaning |
|---------|---------|
| `connection to service named com.apple.linkd.autoShortcut` (4097) | SwiftUI/AppKit trying to register with Shortcuts/Intents under LLDB. This app does not use App Intents — safe to ignore. |
| `Unable to obtain a task name port right ... (os/kern) failure (0x5)` | Typical Xcode debugger noise with ad-hoc signing. Safe to ignore if the app runs normally. Set a **Team** under Signing & Capabilities to reduce this (see below). |
| `AFIsDeviceGreymatterEligible` / `Missing entitlements for os_eligibility` | macOS probing Apple Intelligence eligibility. This app does not use Apple Intelligence — safe to ignore. |
| `Accessibility: Not vending elements ... elementWindow(0) is lower than shield(2001)` | System overlay (Xcode debug bar, menu bar, Stage Manager) sits above the app window. Not an accessibility bug in this app. |
| `invalid display identifier` | Transient WindowServer message during window creation, display hotplug, or debugger attach. Safe to ignore if the UI renders. |
| `CALocalDisplayUpdateBlock returned NO` | Core Animation skipped a display refresh tick — common with SwiftUI + PDFKit under LLDB. Benign if the PDF preview looks correct. |
| `deferral block timed out` / `executed twice` | AppKit/SwiftUI internal timing under the debugger. Safe to ignore. |
| `CoreGraphics PDF has logged an error` / `fopen failed ... errno = 2` | PDFKit loading a PDF with missing embedded fonts, or a brief reload during SwiftUI updates. Benign if the preview renders correctly. |

These do **not** indicate a broken Python connection. Debug parsing uses the shared scheme env var `BANKPARSE_ROOT` → `.venv/bin/python -m bankparse` (see `ParserService.swift`).

To investigate a PDF that fails to render, add scheme environment variable `CG_PDF_VERBOSE=1`.

To confirm messages are debugger noise, use **Product → Run Without Debugging** (⌃⌘R) or launch the built `.app` from Finder — console spam should drop sharply.

To filter Xcode console noise, add excludes for `linkd`, `Greymatter`, and `CALocalDisplayUpdateBlock`.

### Reduce debugger signing noise

The project uses automatic signing. To cut `task name port` messages and other LLDB noise:

1. Open `BankStatementViewer.xcodeproj` in Xcode.
2. Select the **BankStatementViewer** target → **Signing & Capabilities**.
3. Choose your **Team** (Apple ID / Developer account).

No App Intents, Shortcuts, or `os_eligibility` entitlements are required for this app.
