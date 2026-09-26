import SwiftUI
import AppKit

/// Client-only display preferences (Settings ▸ Interface). `@AppStorage`-
/// backed rather than on `ServerOptions`: these never touch a launch flag,
/// so they don't belong in the CLI-args mirroring rule that field owns.

/// The one spelling of each UserDefaults key — `ChatMetrics`, the Settings
/// rows and the appearance modifier all read/write through these, so a typo
/// can't split a reader from its writer.
enum InterfacePrefKey {
    static let appearanceMode = "appearanceMode"
    static let accentColor = "accentColorName"
    static let textSize = "chatTextSize"
    static let compactMode = "compactMode"
    static let chatColumn = "chatColumnWidth"
    /// Default `TerminalTheme` id for new sandbox terminals; a session can
    /// override it from its row's context menu.
    static let terminalTheme = "terminalTheme"
    /// "#RRGGBB" ground painted under the default terminal theme; "" = the
    /// theme's own.
    static let terminalBackground = "terminalBackground"
}

/// How wide a conversation reads: fixed points, so resizing the window spends
/// the margins rather than reflowing the text; a window narrower than the
/// setting wraps to the window.
enum ChatColumnWidth: String, CaseIterable, Identifiable {
    case narrow, medium, wide
    var id: String { rawValue }
    var label: String {
        switch self {
        case .narrow: return "Narrow"
        case .medium: return "Medium"
        case .wide: return "Wide"
        }
    }
    /// nil = the window decides (`ChatMetrics.contentWidthFraction` of it).
    var proseWidth: CGFloat? {
        switch self {
        case .narrow: return 840
        case .medium: return 1260
        case .wide: return nil
        }
    }

    /// Narrower than the column: a user bubble reaching the reply's left edge
    /// stops reading as the other side of the conversation.
    var userBubbleWidth: CGFloat {
        switch self {
        case .narrow: return 700
        case .medium, .wide: return 900
        }
    }

    /// ⌘⌥1 / ⌘⌥2 / ⌘⌥3, narrowest first, in View ▸ Interface. ⌘ combos never
    /// reach an embedded terminal, unlike bare function or Control keys.
    var menuShortcut: KeyEquivalent {
        switch self {
        case .narrow: return "1"
        case .medium: return "2"
        case .wide: return "3"
        }
    }

    static var current: ChatColumnWidth {
        ChatColumnWidth(rawValue: UserDefaults.standard.string(forKey: InterfacePrefKey.chatColumn) ?? "") ?? .wide
    }
}

enum AppAppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    /// nil = follow the system appearance (no override).
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    /// The AppKit twin, for windows whose chrome SwiftUI does not own (the
    /// Quick Launcher's NSPanel + its NSVisualEffectView material — forced-dark
    /// content over a system-light vibrancy reads as a broken half-theme).
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    static var current: AppAppearanceMode {
        AppAppearanceMode(rawValue: UserDefaults.standard.string(forKey: InterfacePrefKey.appearanceMode) ?? "") ?? .system
    }
}

/// The app's type ladder is macOS's, with the odd steps made even: Apple's
/// semantic sizes are 10, 11, 12, 13, 15, 17, 22 and 26, so 11, 13, 15 and 17
/// each move up one point and the rest stay. Every step is therefore even and
/// every step is a size the platform actually uses.
///
/// `AppTypeScale` is the only place a size is stated. A semantic style
/// (`.caption`, `.body`, `.headline` …) is not an option: it would put the odd
/// values back, which is the second ladder this replaced.
enum AppTypeScale {
    /// The floor: `.caption`/`.caption2`/`.footnote` and `labelFontSize` — 10.
    static let floor: CGFloat = 10
    /// Counters and badges.
    static let aux: CGFloat = 10
    /// Small print: `.subheadline` (11 + 1) and `.callout` (12).
    static let small: CGFloat = 12
    /// The default: `.body`/`.headline` (13 + 1) — rows, settings copy, chat,
    /// the sidebar, buttons.
    static let body: CGFloat = 14
    /// Titles: `.title3` (15 + 1) — row, card and pane titles.
    static let title: CGFloat = 16
    /// Headings: `.title2` (17 + 1) — sheets, panes, settings sections.
    static let heading: CGFloat = 18
    /// Page titles: `.title1` — 22.
    static let page: CGFloat = 22
    /// Hero numbers, greetings, empty-state marks: `.largeTitle` — 26.
    static let display: CGFloat = 26
    /// Illustration glyphs, not type.
    static let art: CGFloat = 64
}

enum ChatTextSize: String, CaseIterable, Identifiable {
    case small, medium, large, xlarge
    var id: String { rawValue }
    var label: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Default"
        case .large: return "Large"
        case .xlarge: return "Extra Large"
        }
    }
    /// Prose size (`ChatMetrics.transcriptFontSize`) on the ladder: 12 / 14 /
    /// 16 / 22. `.medium` is the rung the app ships with.
    var proseSize: CGFloat {
        switch self {
        case .small: return AppTypeScale.small
        case .medium: return AppTypeScale.body
        case .large: return AppTypeScale.title
        case .xlarge: return AppTypeScale.page
        }
    }
    /// Fenced/inline code size (`ChatMetrics.transcriptCodeFontSize`) — one
    /// rung under prose, since mono glyphs run wide, and never under the floor.
    var codeSize: CGFloat {
        switch self {
        case .small: return AppTypeScale.aux
        case .medium: return AppTypeScale.small
        case .large: return AppTypeScale.body
        case .xlarge: return AppTypeScale.heading
        }
    }
}

enum AppAccentColor: String, CaseIterable, Identifiable {
    case system, blue, purple, pink, red, orange, yellow, green, graphite
    var id: String { rawValue }
    var label: String { self == .system ? "System" : rawValue.capitalized }
    /// nil = follow the system accent color (no `.tint` override).
    var color: Color? {
        switch self {
        case .system: return nil
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .graphite: return .gray
        }
    }
}

/// Applied to every window scene's root content in `MLXCoreApp.body` — BY
/// HAND per scene, so a new scene CAN forget it; the scan in
/// `AppearanceSettingsTests` is what catches that, the same reasoning as the
/// window-injection rules in app/CLAUDE.md.
struct AppAppearance: ViewModifier {
    @AppStorage(InterfacePrefKey.appearanceMode) private var modeRaw = AppAppearanceMode.system.rawValue
    @AppStorage(InterfacePrefKey.accentColor) private var accentRaw = AppAccentColor.system.rawValue

    func body(content: Content) -> some View {
        let mode = AppAppearanceMode(rawValue: modeRaw) ?? .system
        let accent = AppAccentColor(rawValue: accentRaw) ?? .system
        content
            .preferredColorScheme(mode.colorScheme)
            .tint(accent.color)
    }
}

extension View {
    func appAppearance() -> some View { modifier(AppAppearance()) }
}
