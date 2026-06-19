import Foundation

enum ParserService {
    static func parse(pdfURL: URL) async throws -> ParseResult {
        try await Task.detached(priority: .userInitiated) {
            try runParser(pdfURL: pdfURL)
        }.value
    }

    private static func runParser(pdfURL: URL) throws -> ParseResult {
        let (executable, moduleArgs) = try resolveExecutable()
        var arguments = moduleArgs
        arguments.append(contentsOf: ["--json", pdfURL.path])

        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let errText = String(data: errData, encoding: .utf8) ?? ""

        guard !output.isEmpty else {
            throw ParserError.invalidOutput(errText.isEmpty ? "empty stdout" : errText)
        }

        let decoder = JSONDecoder()
        guard let result = try? decoder.decode(ParseResult.self, from: Data(output.utf8)) else {
            throw ParserError.decodeFailed(String(output.prefix(500)))
        }

        if process.terminationStatus != 0 {
            let message = result.message ?? errText
            if result.error != nil {
                throw ParserError.processFailed(code: process.terminationStatus, message: message)
            }
            throw ParserError.processFailed(code: process.terminationStatus, message: message)
        }

        return result
    }

    private static func resolveExecutable() throws -> (URL, [String]) {
        #if DEBUG
        if let dev = resolveDebugPython() {
            return dev
        }
        #endif

        guard let bundled = Bundle.main.url(
            forResource: "bankparse",
            withExtension: nil,
            subdirectory: "bin"
        ), FileManager.default.isExecutableFile(atPath: bundled.path) else {
            throw ParserError.missingBinary
        }
        return (bundled, [])
    }

    #if DEBUG
    private static func resolveDebugPython() -> (URL, [String])? {
        var candidates: [String] = []
        if let root = ProcessInfo.processInfo.environment["BANKPARSE_ROOT"] {
            candidates.append(root)
        }

        for root in candidates {
            let python = URL(fileURLWithPath: (root as NSString).expandingTildeInPath)
                .appendingPathComponent(".venv/bin/python")
            if FileManager.default.isExecutableFile(atPath: python.path) {
                return (python, ["-m", "bankparse"])
            }
        }
        return nil
    }
    #endif
}
