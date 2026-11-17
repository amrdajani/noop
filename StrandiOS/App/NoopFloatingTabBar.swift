#if os(iOS)
import SwiftUI
import StrandDesign

// MARK: - Floating tab bar (iOS shell chrome)
//
// The iPhone shell's bottom navigation: a floating glass pill holding the primary tabs, plus a
// separate square action button that opens Coach. `RootTabView` keeps the native `TabView` for
// selection state, per-tab `NavigationPath`s and tab-root lifetimes, hides the system bar, and draws
// this view in its place. This file is presentation only: every tap is reported back through
// closures, so the shell's reselect / pop-to-root / scroll-to-top logic stays in one place.

/// Geometry of the floating bar, in points. Measured against a 390pt-wide reference layout:
/// a 290pt pill and a 63.5pt action button with 12pt outer and inner gaps.
enum NoopFloatingTabBarMetrics {
    /// Height of both the pill and the square action button.
    static let barHeight: CGFloat = 63.5
    /// Leading/trailing gap between the bar and the screen edges.
    static let horizontalInset: CGFloat = 12
    /// Gap between the pill and the action button.
    static let actionGap: CGFloat = 12
    static let pillRadius: CGFloat = 32
    static let actionRadius: CGFloat = 24
    /// Even gap between the pill's edge and the selected item's backdrop, on all four sides.
    static let selectedItemInset: CGFloat = 4
    /// Radius of the highlighted backdrop behind the selected item: concentric with the pill
    /// (`pillRadius - selectedItemInset`).
    static let selectedItemRadius: CGFloat = 28
    /// Height of the scrim that fades scrolled content out behind the bar, measured up from the
    /// bottom safe-area edge (the scrim also covers the safe area below it).
    static let scrimHeight: CGFloat = 120
    /// Distance from the physical screen bottom to the bar's bottom edge on home-indicator devices.
    static let bottomFromScreenEdge: CGFloat = 26
    /// Bottom gap above the screen edge on devices with no home indicator (safe-area bottom of 0).
    static let bottomWithoutHomeIndicator: CGFloat = 10
    /// Breathing room kept between the bar's top edge and the last scrolled content.
    static let contentGap: CGFloat = 8

    /// Bottom padding (never negative) and downward visual offset that together put the bar's bottom
    /// edge `bottomFromScreenEdge` above the screen edge. The bar is laid out above the bottom safe
    /// area, so on a 34pt home-indicator inset it is nudged 8pt DOWN with an offset (which does not
    /// affect layout) rather than with negative padding.
    static func placement(safeAreaBottom: CGFloat) -> (padding: CGFloat, offset: CGFloat) {
        let lift = safeAreaBottom > 0
            ? bottomFromScreenEdge - safeAreaBottom
            : bottomWithoutHomeIndicator
        return (max(0, lift), max(0, -lift))
    }

    /// How far the bar's top edge sits above the bottom safe-area edge, plus `contentGap`. Each tab
    /// reserves this much bottom safe area so scroll views and lists end above the bar.
    static func contentReserve(safeAreaBottom: CGFloat) -> CGFloat {
        let p = placement(safeAreaBottom: safeAreaBottom)
        return barHeight + p.padding - p.offset + contentGap
    }
}

/// Colours of the floating bar and the restyled More list. Kept in one place so the shell's chrome is
/// tuned from a single table; the values are the reference measurements for the dark WHOOP-style
/// navigation surfaces.
enum NoopTabChromeTokens {
    /// sRGB colour from a 0xRRGGBB literal.
    static func hex(_ rgb: UInt32, opacity: Double = 1) -> Color {
        Color(.sRGB,
              red: Double((rgb >> 16) & 0xFF) / 255,
              green: Double((rgb >> 8) & 0xFF) / 255,
              blue: Double(rgb & 0xFF) / 255,
              opacity: opacity)
    }

    // Pill
    static let pillTop = Color(.sRGB, red: 40 / 255, green: 47 / 255, blue: 54 / 255, opacity: 0.86)
    static let pillMiddle = Color(.sRGB, red: 30 / 255, green: 36 / 255, blue: 42 / 255, opacity: 0.92)
    static let pillBottom = Color(.sRGB, red: 52 / 255, green: 62 / 255, blue: 70 / 255, opacity: 0.90)
    static let pillBorder = Color.white.opacity(0.07)
    static let barShadow = Color.black.opacity(0.55)
    static let itemSelected = Color.white
    static let itemUnselected = hex(0x8A929A)
    static let selectedBackdropTop = Color.white.opacity(0.10)
    static let selectedBackdropBottom = Color.white.opacity(0.03)

    // Action button
    static let actionCenter = hex(0x3A4560)
    static let actionEdge = hex(0x232A3B)
    static let actionBorder = Color.white.opacity(0.10)
    static let actionRing = hex(0x8786E9)

    // More list
    static let card = hex(0x2E353A)
    static let cardRadius: CGFloat = 16
    static let textSecondary = hex(0xA6ADB3)
    static let textTertiary = hex(0x8A929A)
    static let rowDivider = Color.white.opacity(0.06)
    static let pageTop = hex(0x2C363D)
    static let pageMiddle = hex(0x13171A)
    static let pageBottom = hex(0x0B0F11)
}

/// One primary destination in the pill. `tag` is the `TabView` tag it selects.
struct NoopFloatingTabItem: Identifiable {
    let tag: Int
    let title: LocalizedStringKey
    let icon: String
    var id: Int { tag }
}

/// The floating pill plus (optionally) the Coach action button.
struct NoopFloatingTabBar: View {
    let items: [NoopFloatingTabItem]
    /// The `TabView`'s current selection.
    let selection: Int
    /// Whether the action button is shown. When false the pill takes the full width.
    let showsAction: Bool
    /// Whether the action button's destination is the current tab (drives its selected trait).
    let actionIsSelected: Bool
    /// Accessibility label for the action button.
    let actionTitle: LocalizedStringKey
    let onSelect: (Int) -> Void
    let onAction: () -> Void

    private typealias M = NoopFloatingTabBarMetrics

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Shared by every item's selected backdrop, so it slides from the old item to the new one.
    @Namespace private var selectionNamespace

    var body: some View {
        HStack(alignment: .center, spacing: M.actionGap) {
            pill
            if showsAction {
                NoopFloatingActionButton(title: actionTitle, isSelected: actionIsSelected, action: onAction)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .padding(.horizontal, M.horizontalInset)
        .animation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.24), value: showsAction)
    }

    private var pill: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                NoopFloatingTabButton(
                    item: item,
                    isSelected: item.tag == selection,
                    namespace: selectionNamespace,
                    reduceMotion: reduceMotion
                ) {
                    onSelect(item.tag)
                }
            }
        }
        // Even inset on all four sides: the selected backdrop fills its column inside this padding,
        // so it sits 4pt from the pill edge and is vertically centred.
        .padding(M.selectedItemInset)
        .frame(maxWidth: .infinity)
        .frame(height: M.barHeight)
        .background { NoopFloatingPillBackground() }
        .animation(reduceMotion ? nil : Animation.spring(response: 0.35, dampingFraction: 0.82),
                   value: selection)
    }
}

/// Glass pill: ultra-thin material under a dark translucent gradient, hairline border, drop shadow.
private struct NoopFloatingPillBackground: View {
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: NoopFloatingTabBarMetrics.pillRadius, style: .continuous)
        ZStack {
            shape.fill(.ultraThinMaterial)
            shape.fill(
                LinearGradient(
                    colors: [NoopTabChromeTokens.pillTop, NoopTabChromeTokens.pillMiddle, NoopTabChromeTokens.pillBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            shape.strokeBorder(NoopTabChromeTokens.pillBorder, lineWidth: 1)
        }
        .compositingGroup()
        .shadow(color: NoopTabChromeTokens.barShadow, radius: 12, x: 0, y: 8)
    }
}

/// One item in the pill: outline SF Symbol above its label. A real `Button`, so VoiceOver reads it as
/// one element with the selected trait.
private struct NoopFloatingTabButton: View {
    let item: NoopFloatingTabItem
    let isSelected: Bool
    /// Namespace of the sliding selected backdrop (owned by the bar).
    let namespace: Namespace.ID
    let reduceMotion: Bool
    let action: () -> Void

    /// Scale of the icon; pulsed briefly on tap.
    @State private var iconScale: CGFloat = 1

    /// A light bounce on the tapped icon: a quick lift, then a spring back. Skipped under Reduce Motion.
    private func bounceIcon() {
        guard !reduceMotion else { return }
        withAnimation(.easeOut(duration: 0.1)) { iconScale = 1.12 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { iconScale = 1 }
        }
    }

    var body: some View {
        Button {
            bounceIcon()
            action()
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.icon)
                    .font(.system(size: 24, weight: .regular))
                    // Outline glyphs in both states; selection is carried by colour, weight and backdrop.
                    .environment(\.symbolVariants, .none)
                    .frame(height: 26)
                    .scaleEffect(iconScale)
                Text(item.title)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(isSelected ? NoopTabChromeTokens.itemSelected : NoopTabChromeTokens.itemUnselected)
            // Equal-width column filling the pill's inner height; the icon + label group is centred in it.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background {
                if isSelected {
                    // One backdrop shared across items through the namespace: on a selection change it
                    // slides from the previous column to this one (animated by the pill).
                    RoundedRectangle(cornerRadius: NoopFloatingTabBarMetrics.selectedItemRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [NoopTabChromeTokens.selectedBackdropTop, NoopTabChromeTokens.selectedBackdropBottom],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .matchedGeometryEffect(id: "noop.tabbar.selection", in: namespace)
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.title))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

/// The round Coach button to the right of the pill (same height, centred on it): radial navy fill, hairline border, and a purple
/// ring with a soft glow around a sparkles glyph (NOOP's own mark, not a third-party logo).
private struct NoopFloatingActionButton: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    private typealias M = NoopFloatingTabBarMetrics

    var body: some View {
        Button(action: action) {
            let shape = Circle()
            ZStack {
                shape.fill(
                    RadialGradient(
                        colors: [NoopTabChromeTokens.actionCenter, NoopTabChromeTokens.actionEdge],
                        center: .center,
                        startRadius: 0,
                        endRadius: M.barHeight * 0.7
                    )
                )
                shape.strokeBorder(NoopTabChromeTokens.actionBorder, lineWidth: 1)
                Circle()
                    .stroke(NoopTabChromeTokens.actionRing, lineWidth: 1.6)
                    .frame(width: 33, height: 33)
                    .shadow(color: NoopTabChromeTokens.actionRing.opacity(isSelected ? 0.9 : 0.6), radius: 6)
                    .shadow(color: NoopTabChromeTokens.actionRing.opacity(isSelected ? 0.5 : 0.3), radius: 12)
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .frame(width: M.barHeight, height: M.barHeight)
            .compositingGroup()
            .shadow(color: NoopTabChromeTokens.barShadow, radius: 12, x: 0, y: 8)
            .contentShape(shape)
        }
        .buttonStyle(NoopFloatingPressStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }
}

/// Subtle press-down scale for the action button.
private struct NoopFloatingPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Full-screen page backdrop for the restyled More tab.
struct NoopMorePageBackground: View {
    var body: some View {
        LinearGradient(
            colors: [NoopTabChromeTokens.pageTop, NoopTabChromeTokens.pageMiddle, NoopTabChromeTokens.pageBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#endif
