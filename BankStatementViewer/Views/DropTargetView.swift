import SwiftUI
import UniformTypeIdentifiers

struct DropTargetView: View {
    let onDrop: (URL) -> Void

    @State private var isTargeted = false

    var body: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .strokeBorder(
                isTargeted ? Color.accentColor : Color.secondary.opacity(0.4),
                style: StrokeStyle(lineWidth: 2, dash: [8, 6])
            )
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isTargeted ? Color.accentColor.opacity(0.08) : Color.clear)
            )
            .overlay {
                VStack(spacing: 12) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Drop a bank statement PDF")
                        .font(.title3)
                    Text("Chase and American Express supported")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .onDrop(of: [.pdf, .fileURL], isTargeted: $isTargeted) { providers in
                handleDrop(providers: providers)
            }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) })
            ?? providers.first
        else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil),
                  url.pathExtension.lowercased() == "pdf"
            else { return }
            DispatchQueue.main.async {
                onDrop(url)
            }
        }
        return true
    }
}
