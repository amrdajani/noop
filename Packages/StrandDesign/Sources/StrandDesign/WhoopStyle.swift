import SwiftUI

// MARK: - WHOOP-style dark foundation (iOS)
//
// The iOS re-skin measured from the WHOOP home screen: a flat cool-slate page gradient, solid
// #2E353A cards with 16pt continuous corners and no border/shadow, #434A50 inset chips, white /
// #A6ADB3 / #7E878E text, uppercase wide-tracked section labels, and thin butt-capped score rings.
//
// These are ADDITIVE public tokens/components. The existing `NoopVisualStyle` / `StrandPalette`
// tokens are re-pointed to the same values on iOS (behind `#if os(iOS)`) so every existing screen
// picks the look up without call-site changes; these types are for new code that wants the exact
// WHOOP primitives. Everything here compiles on macOS 13 / iOS 16 / watchOS 10 — on those platforms
// the components simply render with the same values (dark) or the light-mode counterparts.

public enum NoopWhoop {
    // MARK: Data colours
    /// Rest / sleep ring.
    public static let rest = Color(light: "#5C86A3", dark: "#7BA1BB")
    /// Effort / strain ring.
    public static let effort = Color(light: "#1584CC", dark: "#1A9BEB")
    /// Unfilled ring track.
    public static let track = Color(light: "#E1E4E8", dark: "#353C42")

    // MARK: Chrome
    /// Link / accent blue (uppercase tracked links like "CHECK IRON STORES →").
    public static let link = Color(light: "#2A7DB8", dark: "#3E9BD8")
    /// Solid card fill.
    public static let card = Color(light: "#FFFFFF", dark: "#2E353A")
    /// Inset chip / icon square inside a card.
    public static let chip = Color(light: "#E8E9ED", dark: "#434A50")
    /// Secondary text.
    public static let textSecondary = Color(light: "#555861", dark: "#A6ADB3")
    /// Tertiary text.
    public static let textTertiary = Color(light: "#7D808A", dark: "#7E878E")
    /// Hairline divider (white 8% on dark).
    public static let divider = Color(light: "#E4E5E9", dark: "FFFFFF14")

    // MARK: Geometry
    public static let cardRadius: CGFloat = 16
    /// Corner radius for inset chip squares inside cards.
    public static let chipRadius: CGFloat = 6
    /// Inner card padding.
    public static let cardPadding: CGFloat = 16
    /// Vertical gap between cards.
    public static let cardGap: CGFloat = 12
    /// Page side margin.
    public static let pageMargin: CGFloat = 16
    /// Letter-spacing for uppercase section / card titles.
    public static let labelTracking: CGFloat = 2.0
    /// Letter-spacing for uppercase links and CTA labels.
    public static let ctaTracking: CGFloat = 1.6

    // MARK: Page gradient
    /// The dark page gradient, as (offset in POINTS from the top, colour). The final stop is the
    /// bottom of the page, wherever that is; `NoopPageBackground` maps these to unit locations.
    static let pageGradientOffsets: [CGFloat] = [0, 150, 280, 420, 600]
    static let pageGradientColors: [Color] = [
        Color(hex: "#2C363D"),
        Color(hex: "#232A31"),
        Color(hex: "#1D2328"),
        Color(hex: "#171C21"),
        Color(hex: "#13171A"),
    ]
    static let pageGradientBottom = Color(hex: "#0B0F11")
    /// The gradient's minimum overall length. A short backdrop (a header band) is drawn as the top
    /// slice of this same ramp, so it lines up exactly with a full-page backdrop behind it.
    static let pageGradientMinLength: CGFloat = 760

    /// Unit-space stops for a backdrop whose full gradient length is `length` points.
    static func pageStops(length: CGFloat) -> [Gradient.Stop] {
        let l = max(length, pageGradientMinLength)
        var stops: [Gradient.Stop] = []
        for (i, offset) in pageGradientOffsets.enumerated() {
            stops.append(Gradient.Stop(color: pageGradientColors[i], location: offset / l))
        }
        stops.append(Gradient.Stop(color: pageGradientBottom, location: 1))
        return stops
    }
}

// MARK: - Page background

/// The flat WHOOP page backdrop: a vertical slate gradient (#2C363D → #0B0F11) in dark, the plain
/// light canvas in light. No sky, no glow. `ignoresSafeArea()` is the caller's job.
public struct NoopPageBackground: View {
    @Environment(\.colorScheme) private var scheme

    public init() {}

    public var body: some View {
        GeometryReader { proxy in
            fill(height: proxy.size.height)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder private func fill(height: CGFloat) -> some View {
        if scheme == .dark {
            let h = max(height, 1)
            let length = max(h, NoopWhoop.pageGradientMinLength)
            LinearGradient(
                gradient: Gradient(stops: NoopWhoop.pageStops(length: length)),
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: length / h)
            )
        } else {
            NoopVisualStyle.canvas
        }
    }
}

// MARK: - Section label

/// An uppercase, wide-tracked 12pt bold section / card title, optionally with a thin trailing
/// chevron (in which case the label fills the available width so the chevron sits at the edge).
public struct NoopSectionLabel: View {
    private let text: LocalizedStringKey
    private let chevron: Bool

    public init(_ text: LocalizedStringKey, chevron: Bool = false) {
        self.text = text
        self.chevron = chevron
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(text)
                .font(StrandFont.sectionLabel)
                .tracking(NoopWhoop.labelTracking)
                .textCase(.uppercase)
                .foregroundStyle(StrandPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .accessibilityAddTraits(.isHeader)
            if chevron {
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(StrandFont.sectionChevron)
                    .foregroundStyle(NoopWhoop.textSecondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Score ring

/// A WHOOP score ring: a full-circle track plus a progress arc that starts at 12 o'clock and runs
/// clockwise. Butt caps, no glow. `progress` is clamped to 0...1. The ring is inset by half its line
/// width so the stroke stays inside the frame the caller gives it.
public struct NoopScoreRing: View {
    /// The WHOOP ring stroke for a ring of `diameter`: ≈6% of the diameter (5.5pt on the 88pt Today
    /// ring), never thinner than 2.5pt so small inline rings stay legible, and never thicker than
    /// `cap` (the stroke the legacy gauge asked for).
    public static func strokeWidth(forDiameter diameter: CGFloat,
                                   cap: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
        min(cap, max(2.5, diameter * 0.0625))
    }

    private let progress: Double
    private let color: Color
    private let lineWidth: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// True only for the instant before the first-appear sweep: the arc is held at 0, then released
    /// with the draw-in animation. Starts false so a ring that never gets `onAppear` (an off-screen
    /// `ImageRenderer` export, a widget snapshot) still renders its real value.
    @State private var holdsAtZero = false
    @State private var didDrawIn = false

    public init(progress: Double, color: Color, lineWidth: CGFloat = 5.5) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
    }

    /// The arc sweep: ease-out over ~0.9s. `nil` (no animation) under Reduce Motion.
    private var sweep: Animation? {
        reduceMotion ? nil : Animation.easeOut(duration: 0.9)
    }

    private var clamped: Double {
        guard progress.isFinite else { return 0 }
        return min(max(progress, 0), 1)
    }

    public var body: some View {
        let style = StrokeStyle(lineWidth: lineWidth, lineCap: .butt)
        ZStack {
            Circle()
                .stroke(NoopWhoop.track, style: style)
            Circle()
                .trim(from: 0, to: holdsAtZero ? 0 : CGFloat(clamped))
                .stroke(color, style: style)
                .rotationEffect(.degrees(-90))
        }
        .padding(lineWidth / 2)
        // A changed value sweeps to its new position.
        .animation(sweep, value: clamped)
        .onAppear { drawInIfNeeded() }
        .accessibilityHidden(true)
    }

    /// First appearance: sweep the arc from 0 to its value, once. Skipped under Reduce Motion and
    /// when the ring starts empty (a caller that drives its own draw-in passes 0 first; the value
    /// change is then animated by the modifier above).
    private func drawInIfNeeded() {
        guard !didDrawIn else { return }
        didDrawIn = true
        guard !reduceMotion, clamped > 0 else { return }
        let animation = Animation.easeOut(duration: 0.9)
        DispatchQueue.main.async {
            holdsAtZero = true
            DispatchQueue.main.async {
                withAnimation(animation) { holdsAtZero = false }
            }
        }
    }
}

// MARK: - Card

public extension View {
    /// The WHOOP card: inner padding, full available width, a solid `NoopWhoop.card` fill with 16pt
    /// continuous corners. No border, no shadow.
    func noopWhoopCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: NoopWhoop.cardRadius, style: .continuous)
                    .fill(NoopWhoop.card)
            )
    }

    /// The legacy Titanium/Liquid depth shadow (e.g. under a score numeral sitting on a ring). The WHOOP
    /// look is flat, so on iOS this renders nothing; macOS keeps the shadow exactly as before.
    @ViewBuilder
    func noopLegacyShadow(color: Color, radius: CGFloat, y: CGFloat = 0) -> some View {
        #if os(iOS)
        self
        #else
        self.shadow(color: color, radius: radius, x: 0, y: y)
        #endif
    }

    /// An inset chip square (e.g. an icon plate) inside a WHOOP card: `NoopWhoop.chip` fill, 6pt corners.
    func noopWhoopChip(cornerRadius: CGFloat = NoopWhoop.chipRadius) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(NoopWhoop.chip)
        )
    }
}

// MARK: - Buttons

/// The WHOOP primary CTA: a capsule with a 2pt outline, transparent fill, and an UPPERCASE bold
/// tracked label — white on dark (the outline/label use `textPrimary`, so it stays visible in light).
public struct NoopOutlineButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = Capsule(style: .continuous)
        return configuration.label
            .font(StrandFont.ctaLabel)
            .tracking(NoopWhoop.ctaTracking)
            .textCase(.uppercase)
            .foregroundStyle(StrandPalette.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: NoopMetrics.controlHeight)
            .background(shape.fill(StrandPalette.textPrimary.opacity(pressed ? 0.10 : 0)))
            .overlay(shape.strokeBorder(StrandPalette.textPrimary, lineWidth: 2))
            .contentShape(shape)
            .opacity(pressed ? 0.75 : 1)
            .animation(StrandMotion.interactive, value: pressed)
    }
}

/// Press feedback for a tappable card or row: a small settle inward (scale 0.98) plus a slight dim.
/// The label is left untouched otherwise, so the caller keeps its own fill, padding and shape. Under
/// Reduce Motion the scale is dropped and the dim applies without animation.
public struct NoopPressableCardStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        NoopPressableCardBody(label: configuration.label, pressed: configuration.isPressed)
    }
}

/// The body of `NoopPressableCardStyle`, a view so it can read the Reduce Motion setting.
private struct NoopPressableCardBody<Content: View>: View {
    let label: Content
    let pressed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        label
            .scaleEffect(pressed && !reduceMotion ? 0.98 : 1)
            .opacity(pressed ? 0.86 : 1)
            .animation(reduceMotion ? nil : Animation.easeOut(duration: 0.16), value: pressed)
    }
}

/// The WHOOP small square action button: white fill, 10pt corners, black glyph.
public struct NoopSquareActionButtonStyle: ButtonStyle {
    public var size: CGFloat

    public init(size: CGFloat = 36) {
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return configuration.label
            .font(StrandFont.squareActionGlyph)
            .foregroundStyle(Color.black)
            .frame(width: size, height: size)
            .background(shape.fill(Color.white))
            .contentShape(shape)
            .opacity(pressed ? 0.7 : 1)
            .animation(StrandMotion.interactive, value: pressed)
    }
}

public extension ButtonStyle where Self == NoopOutlineButtonStyle {
    /// WHOOP capsule-outline primary CTA.
    static var noopOutline: NoopOutlineButtonStyle { .init() }
}

public extension ButtonStyle where Self == NoopPressableCardStyle {
    /// Press feedback for tappable cards and rows (scale 0.98 + slight dim).
    static var noopPressableCard: NoopPressableCardStyle { .init() }
}

public extension ButtonStyle where Self == NoopSquareActionButtonStyle {
    /// WHOOP white square action button.
    static var noopSquareAction: NoopSquareActionButtonStyle { .init() }
}

#if DEBUG && !os(watchOS)
#Preview("WHOOP style") {
    ZStack {
        NoopPageBackground().ignoresSafeArea()
        ScrollView {
            VStack(alignment: .leading, spacing: NoopWhoop.cardGap) {
                Text(verbatim: "My Day").font(StrandFont.screenTitle).foregroundStyle(StrandPalette.textPrimary)
                VStack(alignment: .leading, spacing: 12) {
                    NoopSectionLabel("Sleep", chevron: true)
                    HStack(spacing: 16) {
                        ZStack {
                            NoopScoreRing(progress: 0.82, color: NoopWhoop.rest)
                            Text(verbatim: "82").font(StrandFont.scoreNumber(30)).foregroundStyle(StrandPalette.textPrimary)
                        }
                        .frame(width: 84, height: 84)
                        ZStack {
                            NoopScoreRing(progress: 0.46, color: NoopWhoop.effort)
                            Text(verbatim: "9.4").font(StrandFont.scoreNumber(30)).foregroundStyle(StrandPalette.textPrimary)
                        }
                        .frame(width: 84, height: 84)
                    }
                    Text(verbatim: "Check iron stores →")
                        .font(StrandFont.ctaLabel).tracking(NoopWhoop.ctaTracking).textCase(.uppercase)
                        .foregroundStyle(NoopWhoop.link)
                }
                .noopWhoopCard()
                Button { } label: { Text(verbatim: "Start activity") }.buttonStyle(.noopOutline)
                Button { } label: { Image(systemName: "plus") }.buttonStyle(.noopSquareAction)
            }
            .padding(.horizontal, NoopWhoop.pageMargin)
        }
    }
    .frame(width: 393, height: 852)
    .preferredColorScheme(.dark)
}
#endif
