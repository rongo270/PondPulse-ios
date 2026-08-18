//
//  Components.swift
//  PondPulse
//
//  Shared UI pieces, rebuilt native: SF Rounded type, capsule buttons that
//  squish on press, SF Symbols for droplets and stars, a material overlay
//  card for win/fail moments. Mirrors the roles of Android's Components.kt.
//

import SwiftUI

extension Font {
    /// The game's voice: SF Rounded, used for every label in the app.
    static func game(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Game-feel press: the control squishes down and springs back.
struct SquishyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    @Environment(\.palette) private var palette
    let text: String
    let action: () -> Void

    init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.game(17, .bold))
                .foregroundStyle(PondPalette.onAccent)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background(palette.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

struct GhostButton: View {
    @Environment(\.palette) private var palette
    let text: String
    let action: () -> Void

    init(_ text: String, action: @escaping () -> Void) {
        self.text = text
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.game(15, .semibold))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.vertical, 13)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(palette.outline, lineWidth: 1.5)
                )
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// The splash budget: filled droplets are still available.
/// The splash budget: filled droplets are still available. Roomy ponds hand out
/// more droplets than fit across a phone, so past `maxDroplets` the row collapses
/// to a single droplet and a count.
struct DropletRow: View {
    @Environment(\.palette) private var palette
    let total: Int
    let left: Int

    private static let maxDroplets = 12

    var body: some View {
        HStack(spacing: 2) {
            if total <= Self.maxDroplets {
                ForEach(0..<total, id: \.self) { index in
                    let available = index < left
                    Image(systemName: available ? "drop.fill" : "drop")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(available ? palette.ripple : palette.textSecondary.opacity(0.4))
                }
            } else {
                Image(systemName: "drop.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.ripple)
                // No spaces around the solidus: with them, bidi reordering shows
                // "5 / 15" as "15 / 5" in Arabic and Hebrew.
                Text("\(left)/\(total)")
                    .font(.game(15, .bold))
                    .foregroundStyle(left <= 2 ? palette.danger : palette.textPrimary)
                    .contentTransition(.numericText())
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: left)
    }
}

struct StarsRow: View {
    @Environment(\.palette) private var palette
    let stars: Int
    var size: CGFloat = 32

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                let earned = index < stars
                Image(systemName: earned ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(earned ? palette.star : palette.textSecondary.opacity(0.5))
                    .symbolEffect(.bounce, value: earned)
            }
        }
    }
}

/// Dimmed full-screen scrim with a centered card, for win/fail moments.
struct OverlayCard<Content: View>: View {
    @Environment(\.palette) private var palette
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            palette.background.opacity(0.72)
                .ignoresSafeArea()
            VStack(spacing: 14) {
                content
            }
            .padding(28)
            .frame(maxWidth: 420)
            .background(palette.surfaceHigh, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: .black.opacity(palette.isDark ? 0.45 : 0.18), radius: 24, y: 10)
            .padding(32)
        }
    }
}

struct SectionTitle: View {
    @Environment(\.palette) private var palette
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.game(24, .bold))
            .foregroundStyle(palette.textPrimary)
            .multilineTextAlignment(.center)
    }
}

/// Circular glassy icon button used on Home and as the screens' back button.
/// A thin progress capsule - how far through a pack or stage the player is.
struct ProgressTrack: View {
    let fraction: Double
    let color: Color
    let track: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(fraction, 0), 1)
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                if clamped > 0 {
                    Capsule().fill(color).frame(width: geo.size.width * clamped)
                }
            }
        }
        .frame(height: height)
    }
}

struct RoundIconButton: View {
    @Environment(\.palette) private var palette
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(palette.textPrimary)
                .frame(width: 42, height: 42)
                .background(palette.surface.opacity(0.88), in: Circle())
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

/// Screen header shared by Packs / Shop / Settings / Rush: back chevron + title.
struct ScreenHeader<Trailing: View>: View {
    @Environment(\.palette) private var palette
    let title: String
    let onBack: () -> Void
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 12) {
            RoundIconButton(systemName: "chevron.backward") { onBack() }
            Text(title)
                .font(.game(24, .bold))
                .foregroundStyle(palette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}

extension ScreenHeader where Trailing == EmptyView {
    init(title: String, onBack: @escaping () -> Void) {
        self.init(title: title, onBack: onBack, trailing: { EmptyView() })
    }
}

/// One medium haptic tick, honoring the in-app setting.
@MainActor
enum Haptics {
    private static let impact = UIImpactFeedbackGenerator(style: .medium)
    private static let soft = UIImpactFeedbackGenerator(style: .soft)

    static func splash(enabled: Bool) {
        guard enabled else { return }
        impact.impactOccurred()
    }

    static func tick(enabled: Bool) {
        guard enabled else { return }
        soft.impactOccurred(intensity: 0.7)
    }
}

// MARK: - Layout helpers

extension View {
    /// Caps a screen's content at phone-ish width and centers it, so iPads
    /// don't stretch the phone layout edge to edge.
    func pondContentWidth(_ maxWidth: CGFloat = 520) -> some View {
        frame(maxWidth: maxWidth)
    }
}
