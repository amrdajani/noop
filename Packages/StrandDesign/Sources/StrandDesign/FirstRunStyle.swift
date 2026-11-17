import SwiftUI

// MARK: - First-run / guided-flow presentation (iOS WHOOP-style)
//
// Shared presentation pieces for the full-screen guided flows: the Terms gate, the onboarding
// wizard, What's New and the Add-a-device wizard. Large centred content on the slate page gradient,
// an UPPERCASE wide-tracked headline in light grey, a 16pt secondary subtitle, a full-width outline
// capsule CTA, and a "connected" success graphic.
//
// Everything here is ORIGINAL geometry (rounded rectangles, capsules, SF Symbols). No third-party
// logos, wordmarks or product art.

public enum NoopFirstRun {
    /// The light-grey headline ink (#C9CED2 on dark).
    public static let headline = Color(light: "#30363B", dark: "#C9CED2")
    /// The success green used by the "connected" graphic.
    public static let success = Color(light: "#0FA85D", dark: "#16D97A")
    /// Letter-spacing for the uppercase headline.
    public static let headlineTracking: CGFloat = 3
    /// Headline point size.
    public static let headlineSize: CGFloat = 22
    /// Subtitle point size.
    public static let subtitleSize: CGFloat = 16
    /// Side margin for full-screen flow content.
    public static let margin: CGFloat = 24
}

public extension Text {
    /// The guided-flow headline: UPPERCASE, wide-tracked, 22pt semibold, light grey, centred.
    func noopFirstRunHeadline() -> some View {
        self
            .font(.system(size: NoopFirstRun.headlineSize, weight: .semibold, design: .default))
            .tracking(NoopFirstRun.headlineTracking)
            .textCase(.uppercase)
            .foregroundStyle(NoopFirstRun.headline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The guided-flow subtitle: 16pt regular, secondary grey, centred.
    func noopFirstRunSubtitle() -> some View {
        self
            .font(.system(size: NoopFirstRun.subtitleSize, weight: .regular, design: .default))
            .foregroundStyle(NoopWhoop.textSecondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Flow CTA

/// The guided-flow call to action: the outline capsule (`NoopOutlineButtonStyle`) plus a disabled
/// dim, so consent-gated buttons ("Accept & Continue") visibly wait for their checkboxes.
public struct NoopFlowCTAButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        NoopOutlineButtonStyle().makeBody(configuration: configuration)
            .opacity(isEnabled ? 1 : 0.35)
    }
}

public extension View {
    /// Style a `Button` as the guided-flow primary action. iOS: the full-width outline capsule with an
    /// UPPERCASE tracked label. macOS / watchOS: the system prominent button tinted with the accent,
    /// exactly as these flows rendered before.
    @ViewBuilder
    func noopFlowCTA() -> some View {
        #if os(iOS)
        self.buttonStyle(NoopFlowCTAButtonStyle())
        #else
        self.buttonStyle(.borderedProminent).tint(StrandPalette.accent)
        #endif
    }
}

// MARK: - Success graphic

/// The "connected" success state: a green glowing circle with a white checkmark, joined by a thin
/// green line to a simple phone outline on the left and a simple band outline on the right. All
/// original shapes. `revealed` drives a calm scale + fade in (pass `true` for a static render).
public struct NoopPairingSuccessGraphic: View {
    private let revealed: Bool
    private let tint: Color

    public init(revealed: Bool = true, tint: Color = NoopFirstRun.success) {
        self.revealed = revealed
        self.tint = tint
    }

    public var body: some View {
        HStack(spacing: 0) {
            phone
            link
            badge
            link
            band
        }
        .frame(maxWidth: 320)
        .accessibilityHidden(true)
    }

    private var link: some View {
        Rectangle()
            .fill(tint)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .scaleEffect(x: revealed ? 1 : 0, y: 1, anchor: .center)
            .opacity(revealed ? 1 : 0)
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: 104, height: 104)
            Circle()
                .fill(tint)
                .frame(width: 72, height: 72)
                .shadow(color: tint.opacity(0.55), radius: 18, x: 0, y: 0)
            Image(systemName: "checkmark")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .scaleEffect(revealed ? 1 : 0.6)
        .opacity(revealed ? 1 : 0)
    }

    /// A plain phone outline: a rounded rectangle with a small speaker capsule.
    private var phone: some View {
        let outline = RoundedRectangle(cornerRadius: 10, style: .continuous)
        return ZStack(alignment: .top) {
            outline
                .fill(NoopWhoop.card)
            outline
                .strokeBorder(NoopFirstRun.headline, lineWidth: 2)
            Capsule(style: .continuous)
                .fill(NoopFirstRun.headline)
                .frame(width: 14, height: 3)
                .padding(.top, 7)
        }
        .frame(width: 44, height: 84)
    }

    /// A plain wrist-band outline: a tall strap capsule with a rounded sensor pod across it.
    private var band: some View {
        let pod = RoundedRectangle(cornerRadius: 8, style: .continuous)
        return ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(NoopFirstRun.headline, lineWidth: 2)
                .frame(width: 26, height: 84)
            pod
                .fill(NoopWhoop.chip)
                .frame(width: 38, height: 40)
            pod
                .strokeBorder(NoopFirstRun.headline, lineWidth: 2)
                .frame(width: 38, height: 40)
        }
        .frame(width: 44, height: 84)
    }
}

// MARK: - Empty state

/// The one empty / pending-data look on iOS: a centred 28pt SF Symbol in tertiary grey, a 15pt
/// semibold title and a 13pt secondary caption. No box, no border.
public struct NoopEmptyState: View {
    private let symbol: String
    private let title: LocalizedStringKey
    private let message: LocalizedStringKey?

    public init(symbol: String, title: LocalizedStringKey, message: LocalizedStringKey? = nil) {
        self.symbol = symbol
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(NoopWhoop.textTertiary)
                .padding(.bottom, 4)
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 15, weight: .semibold, design: .default))
                .foregroundStyle(StrandPalette.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let message {
                Text(message)
                    .font(.system(size: 13, weight: .regular, design: .default))
                    .foregroundStyle(NoopWhoop.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Chart + bar tokens

/// Chart chrome shared by every chart. iOS values follow the WHOOP-style spec (grid white 6%, 10pt
/// tertiary axis labels, 2pt lines, 28% → 0% area fills); macOS / watchOS return the values those
/// charts already used, so nothing moves there.
public enum NoopChartStyle {
    /// Grid line colour.
    public static var grid: Color {
        #if os(iOS)
        return Color(light: "0000000F", dark: "FFFFFF0F")
        #else
        return StrandPalette.hairline.opacity(0.4)
        #endif
    }

    /// Axis label font.
    public static var axisFont: Font {
        #if os(iOS)
        return Font.system(size: 10, weight: .regular, design: .default)
        #else
        return StrandFont.footnote
        #endif
    }

    /// Axis label colour.
    public static var axisLabel: Color {
        #if os(iOS)
        return NoopWhoop.textTertiary
        #else
        return StrandPalette.textTertiary
        #endif
    }

    /// Primary series line width.
    public static var lineWidth: CGFloat {
        #if os(iOS)
        return 2
        #else
        return 2.5
        #endif
    }

    /// Top opacity of a series area fill (fades to 0 at the baseline).
    public static let areaTopOpacity: Double = 0.28

    /// Track colour for progress / pip / range bars.
    public static var barTrack: Color {
        #if os(iOS)
        return NoopWhoop.track
        #else
        return StrandPalette.surfaceInset
        #endif
    }

    /// Bar thickness: a flat 4pt on iOS, the caller's requested height elsewhere.
    public static func barHeight(_ requested: CGFloat) -> CGFloat {
        #if os(iOS)
        return 4
        #else
        return requested
        #endif
    }
}
