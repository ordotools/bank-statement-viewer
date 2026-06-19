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
