import AppKit
import XCTest

@testable import MLXCore

/// Type follows the system's text size. A view names a semantic style and lets
/// macOS size it; a stated point size does not move when the user moves the
/// text-size setting, which is the whole point of the system's ladder.
final class SystemTypeTests: XCTestCase {

    /// Geometry, not type: the transcript renderer's two spacers (a 1pt glyph
    /// gives a table rule its height, 6pt the blank line between blocks) and
    /// the empty state's illustration glyph.
    private static let allowed = [
        "NSFont.systemFont(ofSize: 1)",
        "NSFont.systemFont(ofSize: 6)",
        ".system(size: 64)",
    ]

    private static let pattern = #"(?:\.system\(size:|ofSize:)\s*[0-9.]+"#

    private var sourcesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // MLXCoreTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // app
            .appendingPathComponent("Sources/MLXServe")
    }

    func testNoPointSizeIsStatedForText() throws {
        let regex = try NSRegularExpression(pattern: Self.pattern)
        let walker = try XCTUnwrap(FileManager.default.enumerator(at: sourcesRoot,
                                                                includingPropertiesForKeys: nil))
        var files = 0
        var offenders: [String] = []

        for case let url as URL in walker where url.pathExtension == "swift" {
            files += 1
            let code = SourceScan.strippingComments(try String(contentsOf: url, encoding: .utf8))
            for (number, rawLine) in code.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                let line = String(rawLine)
                if Self.allowed.contains(where: { line.contains($0) }) { continue }
                let range = NSRange(line.startIndex..., in: line)
                guard regex.firstMatch(in: line, range: range) != nil else { continue }
                offenders.append("\(url.lastPathComponent):\(number + 1): " + line.trimmingCharacters(in: .whitespaces))
            }
        }

        XCTAssertGreaterThan(files, 50, "the scan read \(files) files — it is not walking the tree")
        XCTAssertTrue(offenders.isEmpty, """
            Point size(s) stated for text:
            \(offenders.joined(separator: "\n"))

            A point size does not follow the user's text size. Name a semantic
            style instead (`.body`, `.callout`, `.caption2` …), or read the
            system's value with `NSFont.preferredFont(forTextStyle:)`.
            """)
    }

    /// The transcript's own picker is an offset from the system body size, so
    /// it scales with the setting instead of replacing it.
    func testTheTranscriptSettingIsRelativeToTheSystemBody() {
        let body = NSFont.preferredFont(forTextStyle: .body).pointSize
        XCTAssertEqual(ChatTextSize.medium.proseSize, body + 1)
        XCTAssertEqual(ChatTextSize.medium.codeSize, body)
        XCTAssertLessThan(ChatTextSize.small.proseSize, ChatTextSize.medium.proseSize)
        XCTAssertLessThan(ChatTextSize.medium.proseSize, ChatTextSize.xlarge.proseSize)
        XCTAssertLessThan(ChatTextSize.medium.codeSize, ChatTextSize.medium.proseSize)
    }

    /// The code block's font is the system's callout size, not a literal.
    func testTheCodeBlockFontComesFromTheSystem() {
        XCTAssertEqual(CodeBlockLayout.fontSize, NSFont.preferredFont(forTextStyle: .callout).pointSize)
    }
}
