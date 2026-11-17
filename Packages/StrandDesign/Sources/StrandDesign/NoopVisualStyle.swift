import SwiftUI

// MARK: - NOOP visual foundation
//
// These tokens describe the visual treatment used by NOOP's existing views. They deliberately
// contain no navigation, state, or domain semantics: screens keep their current hierarchy and data
// bindings, while cards, gauges, typography, and chrome share one maintainable source of truth.

public enum NoopVisualStyle {
    #if os(iOS)
    // iOS: the WHOOP-style dark re-skin (see WhoopStyle.swift / `NoopWhoop`). Cool slate canvas (the
    // page itself draws `NoopPageBackground`'s gradient; `canvas` is its flat mid-tone for sheets and
    // fallbacks), ONE flat card fill (no top-lit ramp), #434A50 inset chips, white-alpha hairlines.
    // Light values are unchanged.
    public static let canvas = Color(light: "#F3F4F6", dark: "#171C21")
    public static let surface = Color(light: "#FFFFFF", dark: "#2E353A")
    public static let surfaceTop = Color(light: "#FFFFFF", dark: "#2E353A")
    public static let surfaceBottom = Color(light: "#F4F5F7", dark: "#2E353A")
    public static let inset = Color(light: "#E8E9ED", dark: "#434A50")

    // 8-digit hex = RRGGBBAA: white at 4% / 12% / 8%.
    public static let border = Color(light: "#D8DAE0", dark: "FFFFFF0A")
    public static let borderHighlight = Color(light: "#FFFFFF", dark: "FFFFFF1F")
    public static let divider = Color(light: "#E4E5E9", dark: "FFFFFF14")

    public static let primaryText = Color(light: "#17181C", dark: "#FFFFFF")
    public static let secondaryText = Color(light: "#555861", dark: "#A6ADB3")
    public static let tertiaryText = Color(light: "#7D808A", dark: "#7E878E")
    #else
    // Neutral, low-chroma surfaces sampled from the supplied dark-mode reference.
    public static let canvas = Color(light: "#F3F4F6", dark: "#1D1E23")
    public static let surface = Color(light: "#FFFFFF", dark: "#2A2C34")
    public static let surfaceTop = Color(light: "#FFFFFF", dark: "#30323B")
    public static let surfaceBottom = Color(light: "#F4F5F7", dark: "#282A31")
    public static let inset = Color(light: "#E8E9ED", dark: "#23252C")

    public static let border = Color(light: "#D8DAE0", dark: "#373A44")
    public static let borderHighlight = Color(light: "#FFFFFF", dark: "#4B4E59")
    public static let divider = Color(light: "#E4E5E9", dark: "#383A43")

    public static let primaryText = Color(light: "#17181C", dark: "#F7F7FA")
    public static let secondaryText = Color(light: "#555861", dark: "#C3C4CA")
    public static let tertiaryText = Color(light: "#7D808A", dark: "#7D7F88")
    #endif

    public static let mint = Color(light: "#149A78", dark: "#69DDB8")
    public static let mintDeep = Color(light: "#0D765C", dark: "#13A982")
    public static let mintGlow = Color(light: "#38C99E", dark: "#54E6BD")

    #if os(iOS)
    public static let cardRadius: CGFloat = 16
    public static let compactRadius: CGFloat = 10
    #else
    public static let cardRadius: CGFloat = 22
    public static let compactRadius: CGFloat = 16
    #endif
    public static let pillRadius: CGFloat = 999
    public static let pagePadding: CGFloat = 16
    public static let cardPadding: CGFloat = 16
    public static let itemGap: CGFloat = 12
    public static let sectionGap: CGFloat = 26
}

/// Shared card/panel treatment: a solid surface on iOS, gradient and soft elevation elsewhere.
/// `tint` is intentionally faint so metric identity never turns the whole card into a coloured tile.
public struct NoopPanelSurface: View {
    public var tint: Color?
    public var cornerRadius: CGFloat
    public var elevated: Bool
    public var surfaceOpacity: Double
    #if !os(iOS)
    @Environment(\.colorScheme) private var scheme
    #endif

    public init(
        tint: Color? = nil,
        cornerRadius: CGFloat = NoopVisualStyle.cardRadius,
        elevated: Bool = false,
        surfaceOpacity: Double = 1
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.elevated = elevated
        self.surfaceOpacity = surfaceOpacity
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        #if os(iOS)
        // WHOOP-style card: one solid theme-aware fill, no shadow, no tinted rim. The only edge is the
        // `border` hairline (white 4% on dark — effectively invisible, it just keeps adjacent cards from
        // merging on bright displays). `tint` / `elevated` are intentionally ignored on iOS: metric
        // identity comes from the content (rings, coloured numbers), never from the card chrome.
        shape
            .fill(NoopVisualStyle.surface)
            .overlay(shape.strokeBorder(NoopVisualStyle.border, lineWidth: 0.5))
            .opacity(surfaceOpacity)
        #else
        shape
            .fill(
                LinearGradient(
                    colors: [NoopVisualStyle.surfaceTop, NoopVisualStyle.surfaceBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay {
                if let tint {
                    shape.fill(
                        LinearGradient(
                            colors: [tint.opacity(0.055), tint.opacity(0.012), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .overlay(
                shape.strokeBorder(
                    LinearGradient(
                        colors: [NoopVisualStyle.borderHighlight.opacity(0.72), NoopVisualStyle.border.opacity(0.52)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.8
                )
            )
            .shadow(
                color: scheme == .dark ? .black.opacity(elevated ? 0.34 : 0.18) : .black.opacity(0.10),
                radius: elevated ? 18 : 9,
                x: 0,
                y: elevated ? 10 : 5
            )
            .opacity(surfaceOpacity)
        #endif
    }
}

/// Shared edge-to-edge chrome for sheet and split-view headers. Unlike a card it has no
/// rounded outline or elevation, but it uses the same top-lit surface ramp and divider token.
public struct NoopChromeSurface: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [NoopVisualStyle.surfaceTop, NoopVisualStyle.surfaceBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NoopVisualStyle.divider)
                .frame(height: 0.5)
        }
    }
}

public extension View {
    func noopPanel(
        tint: Color? = nil,
        cornerRadius: CGFloat = NoopVisualStyle.cardRadius,
        elevated: Bool = false,
        surfaceOpacity: Double = 1
    ) -> some View {
        background {
            NoopPanelSurface(
                tint: tint,
                cornerRadius: cornerRadius,
                elevated: elevated,
                surfaceOpacity: surfaceOpacity
            )
        }
    }
}
