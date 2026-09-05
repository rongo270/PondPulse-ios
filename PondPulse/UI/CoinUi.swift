//
//  CoinUi.swift
//  PondPulse
//
//  The coin, and the two places a number of them is shown - a port of the
//  Android ui/CoinUi.kt.
//
//  Drawn rather than shipped as an asset so it takes the equipped theme's
//  accent: a gold coin on the neon pond would be the one thing on screen that
//  did not belong to the theme the player chose.
//

import SwiftUI

struct CoinIcon: View {
    @Environment(\.palette) private var palette
    let size: CGFloat

    init(size: CGFloat) { self.size = size }

    var body: some View {
        Canvas { ctx, canvasSize in
            let r = min(canvasSize.width, canvasSize.height) / 2
            let c = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            ctx.fill(circle(c, r), with: .color(palette.accent))
            ctx.stroke(circle(c, r), with: .color(Color.black.opacity(0.18)), style: stroke(r * 0.16))
            // A ripple stamped on the face, so the coin belongs to this game and
            // not to every other game with a gold circle in the corner.
            ctx.stroke(circle(c, r * 0.52), with: .color(Color.white.opacity(0.55)), style: stroke(r * 0.13))
            ctx.fill(circle(c, r * 0.14), with: .color(Color.white.opacity(0.75)))
            ctx.fill(
                circle(CGPoint(x: c.x - r * 0.42, y: c.y - r * 0.42), r * 0.22),
                with: .color(Color.white.opacity(0.35))
            )
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// A balance, for a screen's top bar. Tapping it is optional.
struct CoinChip: View {
    @Environment(\.palette) private var palette
    let coins: Int
    var onTap: (() -> Void)?

    var body: some View {
        let content = HStack(spacing: 6) {
            CoinIcon(size: 16)
            Text("\(coins)")
                .font(.game(14, .bold))
                .foregroundStyle(palette.textPrimary)
                .contentTransition(.numericText())
                // A balance never wraps: it shares the top bar with a title on
                // most screens and with the star count on the home screen.
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(palette.surface.opacity(0.85), in: Capsule())

        if let onTap {
            Button(action: onTap) { content }
                .buttonStyle(SquishyButtonStyle())
        } else {
            content
        }
    }
}

/// A price, for a shop row. `affordable` is what greys it out.
///
/// While `FreeMode.enabled` it says "Free" instead of a number - the price is
/// still passed in and still exists, it simply is not being charged.
struct CoinPrice: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let price: Int
    let affordable: Bool

    var body: some View {
        if FreeMode.enabled {
            Text(strings["shop_free_tag"])
                .font(.game(14, .bold))
                .foregroundStyle(palette.accent)
        } else {
            HStack(spacing: 4) {
                CoinIcon(size: 14)
                Text("\(price)")
                    .font(.game(14, .bold))
                    .foregroundStyle(affordable ? palette.accent : palette.textSecondary.opacity(0.7))
            }
        }
    }
}
