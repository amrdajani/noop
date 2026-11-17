import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Strand Typography (§9.2)
//
// SF Rounded follows the supplied reference's friendly Apple-native geometry. Tabular digits keep live
// metrics stable, while named text styles retain Dynamic Type scaling. SF Mono remains reserved for logs.
//
// All numeric styles use `.monospacedDigit()` so live values don't reflow.

public enum StrandFont {

    // MARK: Family

    /// The house face. iOS uses plain SF Pro (the WHOOP-style re-skin: no rounded glyphs); macOS and
    /// watchOS keep SF Rounded. A computed property (not stored) so no global state is introduced.
    private static var family: Font.Design {
        #if os(iOS)
        return .default
        #else
        return .rounded
        #endif
    }

    /// Named for history: on iOS this is SF Pro (see `family`), elsewhere SF Rounded.
    private static func roundedSystem(_ size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: family)
    }

    // MARK: Scale (§9.2)

    /// Display 64–80 / Bold — the gauge score number. Helvetica Neue 700 with tight
    /// tracking (≈ -0.04em), tabular digits so a changing value never reflows.
    public static func display(_ size: CGFloat = 72) -> Font {
        roundedSystem(size, weight: .bold).monospacedDigit()
    }

    /// The tight tracking for big display numbers (≈ -0.04em). Apply alongside
    /// `display(_:)` at the use site, e.g. `.tracking(StrandFont.displayTracking(72))`.
    public static func displayTracking(_ size: CGFloat = 72) -> CGFloat {
        -size * 0.04
    }

    /// A Helvetica-Neue numeric style at an arbitrary size/weight — the house
    /// numeral. Tabular so live values align. Use anywhere a score/number is shown.
    public static func rounded(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        roundedSystem(size, weight: weight).monospacedDigit()
    }

    /// Title1 28 / Bold. Scales with Dynamic Type.
    public static let title1 = Font.system(.title, design: family, weight: .bold)

    /// Title2 22 / Semibold. Scales with Dynamic Type.
    public static let title2 = Font.system(.title2, design: family, weight: .semibold)

    /// Headline 17 / Semibold. Scales with Dynamic Type.
    public static let headline = Font.system(.headline, design: family, weight: .semibold)

    /// Body 15 / Regular. Scales with Dynamic Type.
    public static let body = Font.system(.body, design: family, weight: .regular)

    /// Subhead 13. Scales with Dynamic Type.
    public static let subhead = Font.system(.subheadline, design: family, weight: .regular)

    /// Caption 12. Scales with Dynamic Type.
    public static let caption = Font.system(.caption, design: family, weight: .regular)

    /// Footnote 11. Scales with Dynamic Type.
    public static let footnote = Font.system(.footnote, design: family, weight: .regular)

    /// Overline 11 / Bold, +1.4 tracking (apply `.tracking(1.4)` at use site;
    /// `overlineText(_:)` does it for you). Sparing ALL-CAPS labels. Scales with Dynamic Type.
    ///
    /// Also the face for compact status copy in constrained chrome (the Today header's sync capsule),
    /// used there WITHOUT the tracking — that is sentence case, not an overline, and the letter-spacing
    /// is what makes an overline read as one.
    public static let overline: Font = {
        #if os(iOS)
        // WHOOP-style: SF Pro bold (not rounded semibold) so the uppercase labels read crisp.
        return Font.system(.caption2, design: .default, weight: .bold)
        #else
        return Font.system(.caption2, design: .rounded, weight: .semibold)
        #endif
    }()

    /// `overline` at a custom point size — same Helvetica face, weight and Dynamic-Type scaling
    /// (relativeTo `.caption2`), just smaller. Passing 11 returns exactly `.overline`. Lets a caller
    /// shrink an ALL-CAPS label to fit a small container without losing accessibility text-scaling.
    public static func overlineScaled(_ size: CGFloat) -> Font {
        #if os(iOS)
        // SF Pro bold, matching `overline` on iOS.
        let base = UIFont.systemFont(ofSize: size, weight: .bold)
        return Font(UIFontMetrics(forTextStyle: .caption2).scaledFont(for: base))
        #elseif canImport(UIKit)
        let base = UIFont.systemFont(ofSize: size, weight: .semibold)
        let descriptor = base.fontDescriptor.withDesign(.rounded) ?? base.fontDescriptor
        let rounded = UIFont(descriptor: descriptor, size: size)
        return Font(UIFontMetrics(forTextStyle: .caption2).scaledFont(for: rounded))
        #elseif canImport(AppKit)
        let base = NSFont.systemFont(ofSize: size, weight: .semibold)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded),
              let rounded = NSFont(descriptor: descriptor, size: size) else {
            return Font(base)
        }
        return Font(rounded)
        #else
        return roundedSystem(size, weight: .semibold)
        #endif
    }

    /// Mono 13 (SF Mono) — raw / log views. Tabular by nature.
    public static let mono = Font.system(size: 13, weight: .regular, design: .monospaced)

    // MARK: Numeric variants (tabular digits)

    /// A numeric style at an arbitrary size/weight, for live values — Helvetica
    /// Neue, tabular digits. This is the tile/value numeral.
    public static func number(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        roundedSystem(size, weight: weight).monospacedDigit()
    }

    /// Helvetica-Neue body number — for inline live values that should align. Scales with Dynamic
    /// Type alongside its sibling `body`/`caption` labels so a value and its label stay matched.
    public static let bodyNumber = Font.system(.body, design: family, weight: .medium).monospacedDigit()

    /// Helvetica-Neue caption number — for small live values (sparklines, chips). Scales with Dynamic Type.
    public static let captionNumber = Font.system(.caption, design: family, weight: .medium).monospacedDigit()

    /// Mono at an arbitrary size.
    public static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    /// The recommended tracking for overline text (wide ALL-CAPS labels, ≈ 0.13em).
    /// iOS uses the wider WHOOP-style letter-spacing.
    #if os(iOS)
    public static let overlineTracking: CGFloat = 1.2
    #else
    public static let overlineTracking: CGFloat = 0.45
    #endif

    // MARK: WHOOP-style faces (ADDED) — SF Pro, used by the iOS re-skin.

    /// Big screen title ("My Day"): SF Pro semibold 28 on iOS (scales with Dynamic Type via `.title`).
    /// macOS / watchOS keep the previous rounded 28 bold header face.
    public static let screenTitle: Font = {
        #if os(iOS)
        return Font.system(.title, design: .default, weight: .semibold)
        #else
        return Font.system(size: 28, weight: .bold, design: .rounded).monospacedDigit()
        #endif
    }()

    /// Uppercase section / card title: SF Pro bold 12 (`.caption`), tracked wide at the use site
    /// (`NoopWhoop.labelTracking`). Scales with Dynamic Type.
    public static let sectionLabel = Font.system(.caption, design: .default, weight: .bold)

    /// The thin trailing chevron beside a section label.
    public static let sectionChevron = Font.system(.caption, design: .default, weight: .semibold)

    /// Uppercase CTA / link label: SF Pro bold 13 (`.footnote`), tracked at the use site.
    public static let ctaLabel = Font.system(.footnote, design: .default, weight: .bold)

    /// Glyph inside the small white square action button.
    public static let squareActionGlyph = Font.system(size: 15, weight: .bold)

    /// Score-ring number: SF Pro bold, CONDENSED width, tabular digits.
    public static func scoreNumber(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.system(size: size, weight: weight, design: .default).width(.condensed).monospacedDigit()
    }

    /// The numeral centred inside a score ring / gauge: `scoreNumber` (SF Pro condensed) on iOS, where
    /// rings follow the WHOOP look, and the house `rounded` numeral on macOS / watchOS (unchanged).
    public static func ringNumber(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        #if os(iOS)
        return scoreNumber(size, weight: weight)
        #else
        return rounded(size, weight: weight)
        #endif
    }
}

// MARK: - Text helpers

public extension Text {
    /// Style as an overline label: ALL-CAPS, bold, +1.4 tracking, tertiary text.
    func strandOverline() -> some View {
        #if os(iOS)
        // WHOOP-style card title: SF Pro bold 12, wide tracking, white.
        return self.font(StrandFont.sectionLabel)
            .tracking(StrandFont.overlineTracking)
            .textCase(.uppercase)
            .foregroundStyle(StrandPalette.textPrimary)
        #else
        return self.font(StrandFont.overline)
            .tracking(StrandFont.overlineTracking)
            .textCase(.uppercase)
            .foregroundStyle(StrandPalette.textSecondary)
        #endif
    }
}

public extension View {
    /// Convenience: an overline-styled label string.
    static func strandOverline(_ string: String) -> some View {
        Text(string).strandOverline()
    }
}

#if DEBUG
#Preview("Typography") {
    ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text("88").font(StrandFont.display(72)).tracking(StrandFont.displayTracking(72)).foregroundStyle(StrandPalette.textPrimary)
            Text("Title 1 / Bold 28").font(StrandFont.title1).foregroundStyle(StrandPalette.textPrimary)
            Text("Title 2 / Semibold 22").font(StrandFont.title2).foregroundStyle(StrandPalette.textPrimary)
            Text("Headline / Semibold 17").font(StrandFont.headline).foregroundStyle(StrandPalette.textPrimary)
            Text("Body / Regular 15 — the thread of you, read in full.")
                .font(StrandFont.body).foregroundStyle(StrandPalette.textPrimary)
            Text("Subhead 13").font(StrandFont.subhead).foregroundStyle(StrandPalette.textSecondary)
            Text("Caption 12").font(StrandFont.caption).foregroundStyle(StrandPalette.textSecondary)
            Text("Footnote 11").font(StrandFont.footnote).foregroundStyle(StrandPalette.textTertiary)
            Text("Overline").strandOverline()
            Text("0xAA 41 00 1c crc32=f3a1  mono 13").font(StrandFont.mono).foregroundStyle(StrandPalette.textSecondary)
            HStack(spacing: 4) {
                Text("HRV").font(StrandFont.caption).foregroundStyle(StrandPalette.textSecondary)
                Text("62").font(StrandFont.bodyNumber).foregroundStyle(StrandPalette.textPrimary)
                Text("ms").font(StrandFont.caption).foregroundStyle(StrandPalette.textTertiary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(width: 520, height: 620)
    .background(StrandPalette.surfaceBase)
    .preferredColorScheme(.dark)
}
#endif
