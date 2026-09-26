import AppKit
import XCTest

@testable import MLXCore

/// The app has ONE type ladder, and `AppTypeScale` is the only place a size is
/// stated. A `.system(size:)` / `ofSize:` literal fails the build, and so does
/// a semantic style: Apple's own values land on 10, 11, 13, 15 and 17 — a
/// second ladder nobody chose, and its small steps cannot be read at all.
final class TypeScaleTests: XCTestCase {

    /// Numbers that are geometry, not type — both are the transcript
    /// renderer's spacers (a 1pt glyph gives a table rule its height, 6pt the
    /// blank line between blocks).
    private static let spacers = [
        "NSFont.systemFont(ofSize: 1)",
        "NSFont.systemFont(ofSize: 6)",
    ]

    private static let sizePattern = #"(?:\.system\(size:|ofSize:)\s*([0-9]+(?:\.[0-9]+)?)"#

    /// The rungs, for the failure messages — never restated by hand.
    private static var rungList: String {
        [AppTypeScale.aux, AppTypeScale.small, AppTypeScale.body, AppTypeScale.title,
         AppTypeScale.heading, AppTypeScale.page, AppTypeScale.display]
            .map { "\(Int($0))" }
            .joined(separator: " / ")
    }

    /// The semantic styles AppKit offers, none of which may be used for text.
    private static let semanticPattern =
        #"(?:\.font\(\s*\.(?:system\(\s*\.)?|Font\.)(largeTitle|title3|title2|title|headline|subheadline|body|callout|footnote|caption2?)\b"#

    private var sourcesRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // MLXCoreTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // app
            .appendingPathComponent("Sources/MLXServe")
    }

    /// Every source file, with comments stripped, as `(name, line, text)`.
    private func sourceLines() throws -> [(file: String, number: Int, line: String)] {
        let walker = try XCTUnwrap(FileManager.default.enumerator(at: sourcesRoot,
                                                                includingPropertiesForKeys: nil))
        var out: [(String, Int, String)] = []
        for case let url as URL in walker where url.pathExtension == "swift" {
            let code = SourceScan.strippingComments(try String(contentsOf: url, encoding: .utf8))
            for (number, rawLine) in code.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
                out.append((url.lastPathComponent, number + 1, String(rawLine)))
            }
        }
        return out
    }

    /// A size is stated once, on the ladder (see `AppTypeScale`), plus `art`
    /// for illustration glyphs.
    func testEveryFontSizeIsAStatedRung() throws {
        let regex = try NSRegularExpression(pattern: Self.sizePattern)
        let lines = try sourceLines()
        var offenders: [String] = []

        for (file, number, line) in lines {
            if Self.spacers.contains(where: { line.contains($0) }) { continue }
            let range = NSRange(line.startIndex..., in: line)
            guard regex.firstMatch(in: line, range: range) != nil else { continue }
            offenders.append("\(file):\(number): " + line.trimmingCharacters(in: .whitespaces))
        }

        XCTAssertGreaterThan(lines.count, 5_000, "the scan read \(lines.count) lines — it is not walking the tree")
        XCTAssertTrue(offenders.isEmpty, """
            Font size(s) stated as a literal:
            \(offenders.joined(separator: "\n"))

            A size is stated once, on `AppTypeScale` (\(Self.rungList)), so the
            ladder stays the ladder.
            """)
    }

    /// The ladder is macOS's with the odd steps made even: seven steps, all
    /// even, each one clear of its neighbour, with `art` above them as
    /// illustration.
    func testTheLadderIsEvenAndClearlySeparated() {
        let rungs = [AppTypeScale.aux, AppTypeScale.small, AppTypeScale.body, AppTypeScale.title,
                     AppTypeScale.heading, AppTypeScale.page, AppTypeScale.display]
        XCTAssertEqual(rungs.first, AppTypeScale.floor, "the floor is the ladder's first rung")
        for (index, rung) in rungs.enumerated() {
            XCTAssertEqual(rung.truncatingRemainder(dividingBy: 2), 0, "\(rung)g is not even")
            if index > 0 {
                XCTAssertGreaterThanOrEqual(rung - rungs[index - 1], 2,
                                            "\(rung)g is not clear of \(rungs[index - 1])g")
            }
        }
        XCTAssertGreaterThan(AppTypeScale.art, AppTypeScale.display, "art sits above the type ladder")
    }

    /// The user may pick a smaller transcript, but every step is a rung: prose
    /// lands on one, code sits one rung under it, and the floor swallows the
    /// gap at the smallest step.
    func testEveryTextSizeSettingStaysOnTheLadder() {
        let rungs = [AppTypeScale.aux, AppTypeScale.small, AppTypeScale.body, AppTypeScale.title,
                     AppTypeScale.heading, AppTypeScale.page, AppTypeScale.display]
        for size in ChatTextSize.allCases {
            XCTAssertTrue(rungs.contains(size.proseSize), "\(size.rawValue) prose \(size.proseSize)g is not a rung")
            XCTAssertTrue(rungs.contains(size.codeSize), "\(size.rawValue) code \(size.codeSize)g is not a rung")
            XCTAssertLessThanOrEqual(size.codeSize, size.proseSize,
                                     "\(size.rawValue): code runs wider than prose, not larger")
            guard let index = rungs.firstIndex(of: size.proseSize) else { continue }
            let below = index == 0 ? AppTypeScale.aux : rungs[index - 1]
            XCTAssertEqual(size.codeSize, below, "\(size.rawValue): code sits one rung under prose")
        }
    }

    /// Apple's small styles render under the floor, so a view that reaches for
    /// one is off the ladder however the rest of the file reads — the model
    /// browser's rows did exactly that, which is why this is a test.
    func testNoSemanticStyleIsUsedForText() throws {
        let regex = try NSRegularExpression(pattern: Self.semanticPattern)
        let lines = try sourceLines()
        var offenders: [String] = []

        for (file, number, line) in lines {
            let range = NSRange(line.startIndex..., in: line)
            guard regex.firstMatch(in: line, range: range) != nil else { continue }
            offenders.append("\(file):\(number): " + line.trimmingCharacters(in: .whitespaces))
        }

        XCTAssertTrue(offenders.isEmpty, """
            Semantic style(s) used for text:
            \(offenders.joined(separator: "\n"))

            Apple's values are 10, 11, 12, 13, 15, 17, 22 and 26 — the odd ones
            are a ladder of their own. Use a rung: \(Self.rungList).
            """)
    }

    /// The monogram is the one size the app derives rather than states, so the
    /// floor has to be inside the derivation: 60% of a 16pt favicon is 9.6pt.
    func testTheFaviconMonogramNeverGoesUnderTheFloor() {
        XCTAssertEqual(FaviconView.monogramFontSize(for: 16), AppTypeScale.floor)
        XCTAssertEqual(FaviconView.monogramFontSize(for: 20), 12)
        XCTAssertEqual(FaviconView.monogramFontSize(for: 40), 24, "a big circle keeps its proportion")
    }
}
