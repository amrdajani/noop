import SwiftUI
import StrandDesign

/// "What's New" — a proper in-app changelog, shown automatically after an update and reachable any
/// time from Settings. It also restates, up top, what NOOP is and what to expect, so people who never
/// open GitHub still understand the experimental footing and the WHOOP 5/MG status.
struct WhatsNewView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            // WHOOP-style: no scenic hero or rule; the header sits straight on the slate gradient.
            header
            #else
            header
                // A scenic Charge-tinted hero behind the title region — the same premium backdrop
                // the Today rings float over, so the changelog opens on-brand.
                .background {
                    ScenicHeroBackground(domain: .charge, starCount: 28, fadesToBase: true)
                }
            Divider().overlay(StrandPalette.hairline)
            #endif
            ScrollView {
                // PERF: the changelog grows with every release, so this is an ever-lengthening column.
                // LazyVStack (byte-identical layout to VStack inside a ScrollView — same leading
                // alignment + sectionGap spacing) builds the off-screen release cards on demand instead
                // of constructing the entire history up-front each time the sheet opens.
                LazyVStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
                    expectationsCard
                    ForEach(Array(AppChangelog.releases.enumerated()), id: \.element.id) { index, release in
                        // The newest release is the headline — give it the brand-green wash; the
                        // rest stay frosted-neutral so the latest stands out at a glance.
                        releaseCard(release, isLatest: index == 0)
                    }
                }
                #if os(iOS)
                .padding(.horizontal, NoopWhoop.pageMargin)
                .padding(.vertical, 12)
                #else
                .padding(20)
                #endif
            }
            #if os(iOS)
            // #697/#horizontal-swipe parity: every other screen (ScreenScaffold, Liquid Today) already
            // stops a vertical scroll from drifting/bouncing the screen left-right. This sheet runs its
            // own ScrollView and had never gotten the fix.
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            #endif
            #if !os(iOS)
            Divider().overlay(StrandPalette.hairline)
            #endif
            footer
        }
        // A fixed 560×640 is right for the macOS sheet window, but on iPhone it's wider than the
        // screen, so the content (and the "Got it" button) ran off the right edge (#185). iOS fills
        // the presented sheet instead.
        #if os(macOS)
        .frame(width: 560, height: 640)
        #else
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // A long changelog scroll → open full-height, with a grabber for swipe-to-dismiss.
        .noopSheetPresentation(largeFirst: true)
        #endif
        #if os(iOS)
        .background { NoopPageBackground().ignoresSafeArea() }
        #else
        .background(StrandPalette.surfaceBase)
        #endif
    }

    #if os(iOS)
    /// iOS: a centred uppercase tracked headline with the version beneath, close button top-right.
    private var header: some View {
        VStack(spacing: 8) {
            Text("WHAT'S NEW")
                .noopFirstRunHeadline()
            Text("NOOP \(AppChangelog.currentVersion)")
                .noopFirstRunSubtitle()
            Text("Release notes").font(StrandFont.caption)
                .foregroundStyle(StrandPalette.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 56)
        .padding(.top, 28)
        .padding(.bottom, 14)
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(StrandPalette.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(NoopWhoop.chip))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
            .padding(.top, 16)
            .padding(.trailing, NoopWhoop.pageMargin)
        }
    }
    #else
    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("WHAT'S NEW").font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textTertiary)
                Text("NOOP \(AppChangelog.currentVersion)")
                    .font(StrandFont.rounded(26, weight: .bold))
                    .foregroundStyle(StrandPalette.textPrimary)
                Text("Release notes").font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(StrandPalette.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(20)
    }
    #endif

    private var expectationsCard: some View {
        NoopCard(tint: StrandPalette.accent) {
            VStack(alignment: .leading, spacing: 14) {
                Text("WHAT TO EXPECT").font(StrandFont.overline)
                    .tracking(StrandFont.overlineTracking)
                    .foregroundStyle(StrandPalette.textSecondary)
                ForEach(AppChangelog.expectations) { e in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: e.icon)
                            .foregroundStyle(StrandPalette.accent)
                            .frame(width: 22)
                            .padding(.top, 2)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(e.title).font(StrandFont.headline)
                                .foregroundStyle(StrandPalette.textPrimary)
                            Text(e.body).font(StrandFont.subhead)
                                .foregroundStyle(StrandPalette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func releaseCard(_ release: AppChangelog.Release, isLatest: Bool = false) -> some View {
        NoopCard(tint: isLatest ? StrandPalette.accent : nil) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    SourceBadge("v\(release.version)")
                    Text(release.title).font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textPrimary)
                    Spacer()
                    Text(release.date).font(StrandFont.caption)
                        .foregroundStyle(StrandPalette.textTertiary)
                }
                ForEach(Array(release.items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(StrandPalette.accent).frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(item).font(StrandFont.subhead)
                            .foregroundStyle(StrandPalette.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    #if os(iOS)
    /// iOS: the full-width outline capsule CTA.
    private var footer: some View {
        Button(action: onClose) {
            Text("Got it")
        }
        .noopFlowCTA()
        .keyboardShortcut(.defaultAction)
        .padding(.horizontal, NoopFirstRun.margin)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }
    #else
    private var footer: some View {
        HStack {
            Spacer()
            Button(action: onClose) {
                Text("Got it").frame(minWidth: 120).padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(StrandPalette.accent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(16)
    }
    #endif
}
