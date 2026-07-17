//
//  ShopView.swift
//  PondPulse
//
//  The Pond Shop: premium upgrade, the consumable hint pack, themes (with a
//  full try-on preview), floater skins and pad styles. Port of the Android
//  ui/ShopScreen.kt; the purchase confirm is a native alert and grants
//  locally, exactly like the Android pre-release placeholder.
//

import SwiftUI

struct ShopView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    @State private var previewTheme: ThemeItem?
    @State private var showPremiumDetails = false
    @State private var restored = false

    var body: some View {
        // Premium exclusives only join the shelves once premium is owned; before
        // that they live inside the premium card's detail view.
        let visibleThemes = Catalog.themes.filter { vm.isPremium || !$0.unlock.isPremium }
        let visibleSkins = Catalog.skins.filter { vm.isPremium || !$0.unlock.isPremium }
        let visiblePads = Catalog.pads.filter { vm.isPremium || !$0.unlock.isPremium }

        ZStack {
            VStack(spacing: 0) {
                ScreenHeader(title: strings["shop_title"], onBack: { vm.back() })

                ScrollView {
                    LazyVStack(spacing: 10) {
                        PremiumCard(
                            isPremium: vm.isPremium,
                            levelCount: vm.premiumLevelCount(),
                            price: vm.price(Catalog.premiumId, fallback: Catalog.premiumPrice),
                            onOpenDetails: { showPremiumDetails = true },
                            onBuy: { buy(Catalog.premiumId) }
                        )

                        if !vm.isPremium {
                            HintPackCard(
                                hintsLeft: vm.hintsLeft,
                                price: vm.price(Catalog.hintsId, fallback: Catalog.hintsPrice)
                            ) {
                                buy(Catalog.hintsId)
                            }
                        }

                        SectionHeader(
                            title: strings["shop_section_themes"],
                            desc: strings["shop_section_themes_desc"],
                            ownedCount: visibleThemes.count { usable($0.unlock, Catalog.themeProductId($0.id)) },
                            totalCount: visibleThemes.count
                        )
                        ForEach(visibleThemes) { theme in
                            ThemeRow(
                                theme: theme,
                                selected: theme.id == vm.themeId,
                                usable: usable(theme.unlock, Catalog.themeProductId(theme.id)),
                                price: resolvedPrice(theme.unlock, Catalog.themeProductId(theme.id)),
                                onOpen: { previewTheme = theme }
                            )
                        }

                        SectionHeader(
                            title: strings["shop_section_skins"],
                            desc: strings["shop_section_skins_desc"],
                            ownedCount: visibleSkins.count { usable($0.unlock, Catalog.skinProductId($0.id)) },
                            totalCount: visibleSkins.count
                        )
                        grid(items: visibleSkins) { skin in
                            ShopGridCard(
                                name: strings[skin.nameKey],
                                unlock: skin.unlock,
                                selected: skin.id == vm.skinId,
                                usable: usable(skin.unlock, Catalog.skinProductId(skin.id)),
                                displayPrice: resolvedPrice(skin.unlock, Catalog.skinProductId(skin.id)),
                                onSelect: { vm.selectSkin(skin.id) },
                                onBuy: { _ in
                                    buy(Catalog.skinProductId(skin.id)) { vm.selectSkin(skin.id) }
                                }
                            ) {
                                SkinPreview(skinId: skin.id).aspectRatio(1.35, contentMode: .fit)
                            }
                        }

                        SectionHeader(
                            title: strings["shop_section_pads"],
                            desc: strings["shop_section_pads_desc"],
                            ownedCount: visiblePads.count { usable($0.unlock, Catalog.padProductId($0.id)) },
                            totalCount: visiblePads.count
                        )
                        grid(items: visiblePads) { pad in
                            ShopGridCard(
                                name: strings[pad.nameKey],
                                unlock: pad.unlock,
                                selected: pad.id == vm.padId,
                                usable: usable(pad.unlock, Catalog.padProductId(pad.id)),
                                displayPrice: resolvedPrice(pad.unlock, Catalog.padProductId(pad.id)),
                                onSelect: { vm.selectPad(pad.id) },
                                onBuy: { _ in
                                    buy(Catalog.padProductId(pad.id)) { vm.selectPad(pad.id) }
                                }
                            ) {
                                PadPreview(padId: pad.id).aspectRatio(1.35, contentMode: .fit)
                            }
                        }

                        Text(strings["shop_note"])
                            .font(.game(12))
                            .foregroundStyle(palette.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)

                        // App Store restore, for non-consumables on a new device.
                        Button {
                            Task {
                                await vm.restorePurchases()
                                restored = true
                            }
                        } label: {
                            Text(restored ? "✓ " + strings["shop_restored"] : strings["shop_restore"])
                                .font(.game(13, .semibold))
                                .foregroundStyle(restored ? palette.accent : palette.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }

            // Blocks double-taps while the App Store payment sheet is up.
            if vm.purchasing {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ProgressView()
                    .controlSize(.large)
                    .tint(palette.accent)
            }

            // Full theme try-on: the dialog is re-themed with the candidate palette.
            if let theme = previewTheme {
                ThemePreviewDialog(
                    theme: theme,
                    skinId: vm.skinId,
                    padId: vm.padId,
                    selected: theme.id == vm.themeId,
                    usable: usable(theme.unlock, Catalog.themeProductId(theme.id)),
                    price: resolvedPrice(theme.unlock, Catalog.themeProductId(theme.id)),
                    highestSolved: vm.highestSolvedLevel(),
                    onApply: {
                        vm.selectTheme(theme.id)
                        previewTheme = nil
                    },
                    onBuy: { _ in
                        previewTheme = nil
                        buy(Catalog.themeProductId(theme.id)) { vm.selectTheme(theme.id) }
                    },
                    onDismiss: { previewTheme = nil }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: previewTheme?.id)
        .sheet(isPresented: $showPremiumDetails) {
            PremiumDetailsSheet(
                isPremium: vm.isPremium,
                levelCount: vm.premiumLevelCount(),
                price: vm.price(Catalog.premiumId, fallback: Catalog.premiumPrice),
                onBuy: {
                    showPremiumDetails = false
                    buy(Catalog.premiumId)
                }
            )
            .environment(\.palette, palette)
            .environment(\.strings, strings)
        }
    }

    /// Runs the App Store payment sheet (which is the confirmation) and equips
    /// the item once the verified purchase lands.
    private func buy(_ productId: String, onGranted: @escaping () -> Void = {}) {
        Task {
            if await vm.purchase(productId) { onGranted() }
        }
    }

    private func usable(_ unlock: Unlock, _ productId: String) -> Bool {
        vm.isOwned(unlock, productId: productId)
    }

    /// The App Store's localized price for a paid item, Catalog's until loaded.
    private func resolvedPrice(_ unlock: Unlock, _ productId: String) -> String? {
        unlock.price.map { vm.price(productId, fallback: $0) }
    }

    private func grid<Item: Identifiable, Card: View>(
        items: [Item], @ViewBuilder card: @escaping (Item) -> Card
    ) -> some View {
        let rows = stride(from: 0, to: items.count, by: 3).map { Array(items[$0..<min($0 + 3, items.count)]) }
        return ForEach(Array(rows.enumerated()), id: \.offset) { _, rowItems in
            HStack(alignment: .top, spacing: 10) {
                ForEach(rowItems) { item in
                    card(item).frame(maxWidth: .infinity)
                }
                ForEach(0..<(3 - rowItems.count), id: \.self) { _ in
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Cards

private struct PremiumCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let isPremium: Bool
    let levelCount: Int
    let price: String
    let onOpenDetails: () -> Void
    let onBuy: () -> Void

    var body: some View {
        Button(action: onOpenDetails) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(palette.accent)
                    Text(strings["shop_premium_title"])
                        .font(.game(17, .bold))
                        .foregroundStyle(palette.textPrimary)
                    Spacer()
                    if isPremium {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(palette.accent)
                    }
                }
                if isPremium {
                    Text(strings["shop_premium_owned"])
                        .font(.game(14))
                        .foregroundStyle(palette.textSecondary)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach([
                            strings["shop_premium_point_levels", levelCount],
                            strings["shop_premium_point_open"],
                            strings["shop_premium_point_hints"],
                            strings["shop_premium_point_exclusive"],
                            strings["shop_premium_point_future"],
                            strings["shop_premium_point_once"],
                        ], id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(palette.accent)
                                Text(point)
                                    .font(.game(14))
                                    .foregroundStyle(palette.textPrimary)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                    }
                    Text(strings["shop_premium_tap_details"])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary.opacity(0.8))
                        .padding(.top, 2)
                    PrimaryButton(strings["shop_premium_cta", price], action: onBuy)
                        .padding(.top, 6)
                }
            }
            .padding(16)
            .background(palette.surfaceHigh, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(palette.accent.opacity(0.8), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Consumable 50-hint pack; premium owners never see it (hints are unlimited).
private struct HintPackCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let hintsLeft: Int
    let price: String
    let onBuy: () -> Void

    var body: some View {
        Button(action: onBuy) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(palette.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings["shop_hints_title"])
                        .font(.game(15, .bold))
                        .foregroundStyle(palette.textPrimary)
                    Text(strings["shop_hints_desc", hintsLeft])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                Text(price)
                    .font(.game(15, .bold))
                    .foregroundStyle(palette.accent)
            }
            .padding(14)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle())
        .padding(.top, 10)
    }
}

private struct SectionHeader: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let title: String
    let desc: String
    let ownedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.game(17, .bold))
                    .foregroundStyle(palette.textPrimary)
                Spacer()
                Text(strings["shop_count", ownedCount, totalCount])
                    .font(.game(13, .semibold))
                    .foregroundStyle(palette.textSecondary)
            }
            Text(desc)
                .font(.game(12))
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 18)
        .padding(.bottom, 2)
    }
}

private struct ThemeRow: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let theme: ThemeItem
    let selected: Bool
    let usable: Bool
    let price: String?
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                ThemePreview(palette: theme.palette)
                    .frame(width: 76, height: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings[theme.nameKey])
                        .font(.game(15, .semibold))
                        .foregroundStyle(palette.textPrimary)
                    Text(strings["shop_theme_tap_preview"])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary.opacity(0.8))
                }
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(palette.accent)
                } else if usable {
                    Text(strings["shop_select"])
                        .font(.game(13, .semibold))
                        .foregroundStyle(palette.textSecondary)
                } else if let level = theme.unlock.rewardLevel {
                    Text(strings["shop_reward_level", level])
                        .font(.game(13, .semibold))
                        .foregroundStyle(palette.textSecondary)
                } else if let price {
                    Text(price)
                        .font(.game(13, .bold))
                        .foregroundStyle(palette.accent)
                }
            }
            .padding(10)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? palette.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

struct ShopGridCard<Preview: View>: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let name: String
    let unlock: Unlock
    let selected: Bool
    let usable: Bool
    var displayPrice: String? = nil
    let onSelect: () -> Void
    let onBuy: (String) -> Void
    @ViewBuilder let preview: Preview

    var body: some View {
        Button {
            if selected {
                // already equipped
            } else if usable {
                onSelect()
            } else if let price = displayPrice ?? unlock.price {
                onBuy(price)
            }
        } label: {
            VStack(spacing: 6) {
                preview
                    .overlay {
                        if !usable, unlock.rewardLevel != nil {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(palette.background.opacity(0.55))
                            Image(systemName: "lock.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(palette.textPrimary.opacity(0.9))
                        }
                    }
                Text(name)
                    .font(.game(13, .semibold))
                    .foregroundStyle(palette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(caption)
                    .font(.game(11, usable || unlock.price == nil ? .regular : .bold))
                    .foregroundStyle(captionColor)
            }
            .padding(8)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(selected ? palette.accent : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(SquishyButtonStyle())
    }

    private var caption: String {
        if selected { return strings["shop_selected"] }
        if usable { return strings["shop_select"] }
        if let level = unlock.rewardLevel { return strings["shop_reward_level", level] }
        return displayPrice ?? unlock.price ?? ""
    }

    private var captionColor: Color {
        if selected { return palette.accent }
        if !usable, unlock.price != nil { return palette.accent }
        return palette.textSecondary
    }
}

// MARK: - Theme try-on

/// Full theme try-on: the dialog itself is re-themed with the candidate
/// palette and shows a little staged pond, so the buyer sees exactly what
/// they get.
private struct ThemePreviewDialog: View {
    @Environment(\.strings) private var strings
    let theme: ThemeItem
    let skinId: String
    let padId: String
    let selected: Bool
    let usable: Bool
    let price: String?
    let highestSolved: Int
    let onApply: () -> Void
    let onBuy: (String) -> Void
    let onDismiss: () -> Void

    var body: some View {
        let palette = theme.palette
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { onDismiss() }
            VStack(spacing: 0) {
                Text(strings[theme.nameKey])
                    .font(.game(22, .bold))
                    .foregroundStyle(palette.textPrimary)
                Text(strings["shop_preview_hint"])
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
                    .padding(.top, 4)
                ThemeScene(palette: palette, skinId: skinId, padId: padId)
                    .aspectRatio(7.0 / 4.0, contentMode: .fit)
                    .padding(.top, 14)
                Group {
                    if selected {
                        GhostButton(strings["close"], action: onDismiss)
                    } else if usable {
                        PrimaryButton(strings["shop_preview_use"], action: onApply)
                    } else if let price {
                        PrimaryButton(strings["shop_buy_confirm", price]) { onBuy(price) }
                    } else if let level = theme.unlock.rewardLevel {
                        Text(strings["shop_reward_unlock_at", level, highestSolved])
                            .font(.game(14))
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.top, 16)
                if !selected {
                    Button(strings["shop_cancel"], action: onDismiss)
                        .font(.game(14, .semibold))
                        .foregroundStyle(palette.textSecondary)
                        .padding(.top, 8)
                }
            }
            .padding(20)
            .background(palette.background, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.4), radius: 28, y: 12)
            .padding(28)
        }
        .environment(\.palette, palette)
    }
}

/// A staged 7×4 pond with a bit of everything, painted in the candidate palette.
private struct ThemeScene: View {
    let palette: PondPalette
    let skinId: String
    let padId: String

    var body: some View {
        Canvas { ctx, size in
            let cols = 7
            let rows = 4
            let cell = min(size.width / CGFloat(cols), size.height / CGFloat(rows))
            let originX = (size.width - cell * CGFloat(cols)) / 2
            let originY = (size.height - cell * CGFloat(rows)) / 2
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.background))

            func cellRect(_ x: Int, _ y: Int) -> CGRect {
                CGRect(x: originX + CGFloat(x) * cell, y: originY + CGFloat(y) * cell, width: cell, height: cell)
            }

            // Banks in two corners so the rim shows.
            let banks: Set<[Int]> = [[0, 0], [6, 3]]
            for y in 0..<rows {
                for x in 0..<cols {
                    if banks.contains([x, y]) { continue }
                    let deep = (x + y) % 2 == 0
                    ctx.fill(Path(cellRect(x, y)), with: .color(deep ? palette.waterDeep : palette.water))
                }
            }
            for y in 0..<rows {
                for x in 0..<cols {
                    if banks.contains([x, y]) { continue }
                    drawWaterRim(&ctx, pos: Pos(x: x, y: y), rect: cellRect(x, y), palette: palette) { p in
                        p.x < 0 || p.x >= cols || p.y < 0 || p.y >= rows || banks.contains([p.x, p.y])
                    }
                }
            }

            drawCurrent(&ctx, rect: cellRect(5, 1), dir: .right, phase: 0.25, palette: palette)
            drawPadStyle(&ctx, padId: padId, rect: cellRect(1, 3), palette: palette, ring: nil)
            drawPadStyle(&ctx, padId: padId, rect: cellRect(5, 3), palette: palette, ring: palette.padRing(.red))
            drawRock(&ctx, rect: cellRect(4, 0), palette: palette)
            drawFloaterSkin(&ctx, skinId: skinId, rect: cellRect(1, 1), palette: palette, color: nil)
            drawFloaterSkin(&ctx, skinId: skinId, rect: cellRect(3, 2), palette: palette, color: .red)
            drawTurtle(&ctx, cellRect(2, 0), palette)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Premium details

/// Everything the premium upgrade grants, previews included. The exclusive
/// theme, friends and pads only appear here until premium is owned.
private struct PremiumDetailsSheet: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    @Environment(\.dismiss) private var dismiss
    let isPremium: Bool
    let levelCount: Int
    let price: String
    let onBuy: () -> Void

    var body: some View {
        let exclusiveThemes = Catalog.themes.filter(\.unlock.isPremium)
        let exclusiveSkins = Catalog.skins.filter(\.unlock.isPremium)
        let exclusivePads = Catalog.pads.filter(\.unlock.isPremium)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(palette.accent)
                    Text(strings["shop_premium_title"])
                        .font(.game(22, .bold))
                        .foregroundStyle(palette.textPrimary)
                }
                .padding(.top, 24)
                .padding(.bottom, 12)

                ForEach([
                    strings["shop_premium_point_levels", levelCount],
                    strings["shop_premium_point_open"],
                    strings["shop_premium_point_hints"],
                    strings["shop_premium_point_future"],
                    strings["shop_premium_point_once"],
                ], id: \.self) { point in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(palette.accent)
                        Text(point)
                            .font(.game(13))
                            .foregroundStyle(palette.textPrimary)
                    }
                    .padding(.vertical, 2)
                }

                sectionLabel(strings["shop_premium_exclusive_theme"])
                ForEach(exclusiveThemes) { theme in
                    HStack(spacing: 12) {
                        ThemePreview(palette: theme.palette)
                            .frame(width: 76, height: 52)
                        Text(strings[theme.nameKey])
                            .font(.game(14))
                            .foregroundStyle(palette.textPrimary)
                    }
                }

                sectionLabel(strings["shop_premium_exclusive_friends"])
                HStack(alignment: .top, spacing: 10) {
                    ForEach(exclusiveSkins) { skin in
                        VStack(spacing: 4) {
                            SkinPreview(skinId: skin.id)
                                .aspectRatio(1.35, contentMode: .fit)
                            Text(strings[skin.nameKey])
                                .font(.game(12, .medium))
                                .foregroundStyle(palette.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                sectionLabel(strings["shop_premium_exclusive_pads"])
                HStack(alignment: .top, spacing: 10) {
                    ForEach(exclusivePads) { pad in
                        VStack(spacing: 4) {
                            PadPreview(padId: pad.id)
                                .aspectRatio(1.35, contentMode: .fit)
                            Text(strings[pad.nameKey])
                                .font(.game(12, .medium))
                                .foregroundStyle(palette.textPrimary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    ForEach(0..<max(3 - exclusivePads.count, 0), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }

                Group {
                    if isPremium {
                        GhostButton(strings["close"]) { dismiss() }
                    } else {
                        PrimaryButton(strings["shop_premium_cta", price], action: onBuy)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
        }
        .presentationBackground(palette.background)
        .presentationDetents([.large])
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.game(14, .bold))
            .foregroundStyle(palette.accent)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }
}

// MARK: - Previews shared with the win card

/// Small pond swatch: the theme's water, pad and duckling at a glance.
struct ThemePreview: View {
    let palette: PondPalette

    var body: some View {
        Canvas { ctx, size in
            ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.background))
            let pool = CGRect(
                x: size.width * 0.08, y: size.height * 0.14,
                width: size.width * 0.84, height: size.height * 0.72
            )
            ctx.fill(Path(roundedRect: pool, cornerRadius: size.height * 0.12), with: .color(palette.water))
            let cell = pool.height * 0.9
            let padRect = CGRect(x: pool.minX + pool.width * 0.12, y: pool.midY - cell / 2, width: cell, height: cell)
            drawPadStyle(&ctx, padId: "lily", rect: padRect, palette: palette, ring: nil)
            let duckRect = CGRect(x: pool.maxX - pool.width * 0.12 - cell, y: pool.midY - cell / 2, width: cell, height: cell)
            drawFloaterSkin(&ctx, skinId: "duck", rect: duckRect, palette: palette, color: nil)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// The skin swimming on a patch of the current theme's water.
struct SkinPreview: View {
    @Environment(\.palette) private var palette
    let skinId: String
    var color: DuckColor? = nil

    var body: some View {
        Canvas { ctx, size in
            drawWaterPatch(&ctx, size: size, palette: palette)
            let side = min(size.width, size.height) * 0.92
            let rect = CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)
            drawFloaterSkin(&ctx, skinId: skinId, rect: rect, palette: palette, color: color)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct PadPreview: View {
    @Environment(\.palette) private var palette
    let padId: String

    var body: some View {
        Canvas { ctx, size in
            drawWaterPatch(&ctx, size: size, palette: palette)
            let side = min(size.width, size.height) * 0.92
            let rect = CGRect(x: (size.width - side) / 2, y: (size.height - side) / 2, width: side, height: side)
            drawPadStyle(&ctx, padId: padId, rect: rect, palette: palette, ring: nil)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Checkered two-tone water behind the shop previews.
nonisolated private func drawWaterPatch(_ ctx: inout GraphicsContext, size: CGSize, palette: PondPalette) {
    ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.water))
    ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width / 2, height: size.height / 2)), with: .color(palette.waterDeep))
    ctx.fill(
        Path(CGRect(x: size.width / 2, y: size.height / 2, width: size.width / 2, height: size.height / 2)),
        with: .color(palette.waterDeep)
    )
}

/// Shown on the win overlay when this level just unlocked a new reward.
struct RewardUnlockBanner<Preview: View>: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let name: String
    let onOpenShop: () -> Void
    @ViewBuilder let preview: Preview

    var body: some View {
        HStack(spacing: 10) {
            preview
            VStack(alignment: .leading, spacing: 2) {
                Text(strings["win_reward_title"])
                    .font(.game(14, .bold))
                    .foregroundStyle(palette.accent)
                Text(strings["win_reward_body", name])
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            Button(strings["win_reward_equip"], action: onOpenShop)
                .font(.game(13, .bold))
                .foregroundStyle(palette.accent)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
