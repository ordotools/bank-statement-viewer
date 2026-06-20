import PDFKit
import SwiftUI

struct PDFPreviewView: NSViewRepresentable {
    let url: URL?

    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateNSView(_ pdfView: PDFView, context: Context) {
        guard let url else {
            pdfView.document = nil
            return
        }
        guard FileManager.default.fileExists(atPath: url.path) else {
            pdfView.document = nil
            return
        }
        if pdfView.document?.documentURL != url {
            pdfView.document = PDFDocument(url: url)
        }
    }
}
