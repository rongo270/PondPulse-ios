//
//  ShopView.swift
//  PondPulse
//
//  The Pond Shop: the premium upgrade, the hint pack, the coin packs, and the
//  three cosmetic shelves - friends, lily pads and themes (with a full try-on
//  preview). Port of the Android ui/ShopScreen.kt.
//
//  Two currencies, and which one a card uses is decided by its `Unlock`:
//  everything cosmetic is `.coins` and is settled locally against `CoinBank`
//  after a confirm alert; premium, the hint pack and the coin packs are real
//  StoreKit products, where Apple's payment sheet *is* the confirmation and no
//  alert of ours goes in front of it.
//
//  The front page shows a taster of each shelf and sends the rest to
//  `ShopShelfView`: with 36 friends and 22 pads on sale, one page was several
//  screens of thumb work before the themes even appeared.
//

import SwiftUI

/// How many of each shelf the shop's front page shows. The rest live on the
/// shelf's own page, one tap away.
private let skinsPreview = 6
private let padsPreview = 3
private let themesPreview = 2

/// The handful a front-page shelf shows: whatever is equipped first, then
/// catalog order - free, then earned, then paid - so the taster is never all
/// padlocks and never only things already owned.
private func previewSlice<T>(_ all: [T], _ limit: Int, _ isSelected: (T) -> Bool) -> [T] {
    guard all.count > limit else { return all }
    return Array((all.filter(isSelected) + all.filter { !isSelected($0) }).prefix(limit))
}

/// A coin purchase waiting for its confirm alert. Granting equips the item too.
///
/// The price rides on the pending buy rather than being re-derived at confirm
/// time, so the alert can never charge a price different from the one the card
/// showed.
struct PendingBuy: Identifiable {
    let productId: String
    let name: String
    let price: Int
    let onGranted: () -> Void

    var id: String { productId }
}

struct ShopView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    @State private var previewTheme: ThemeItem?
    @State private var pending: PendingBuy?
    @State private var showPremiumDetails = false
    @State private var restored = false

    var body: some View {
        let shelves = ShopShelves(vm: vm)

        ZStack {
            VStack(spacing: 0) {
                ScreenHeader(title: strings["shop_title"], onBack: { vm.back() }) {
                    CoinChip(coins: vm.coins)
                }

                ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        // Closed testing grants premium to everyone, so there is
                        // nothing for its card to offer and nothing for the coin
                        // packs to sell. Both come back with the economy.
                        if !FreeMode.enabled {
                            PremiumCard(
                                isPremium: vm.isPremium,
                                levelCount: vm.premiumLevelCount(),
                                price: vm.price(Catalog.premiumId, fallback: Catalog.premiumPrice),
                                onOpenDetails: { showPremiumDetails = true },
                                onBuy: { buyForMoney(Catalog.premiumId) }
                            )
                        }

                        if !vm.isPremium {
                            HintPackCard(
                                hintsLeft: vm.hintsLeft,
                                affordable: vm.canAfford(CoinBank.hintBundle * CoinBank.priceHint),
                                packPrice: vm.price(Catalog.hintsId, fallback: Catalog.hintsPrice),
                                onBuyWithCoins: { vm.buyHints(count: CoinBank.hintBundle) },
                                onBuyPack: { buyForMoney(Catalog.hintsId) }
                            )
                        }

                        if !FreeMode.enabled {
                            CoinPacksCard(coins: vm.coins, priceOf: { vm.price($0, fallback: $1) }) { productId in
                                buyForMoney(productId)
                            }
                        }

                        // Friends first - they are what the player looks at all
                        // game - then pads, then themes, which are full-width
                        // rows and so cost the most height per item.
                        SectionHeader(
                            title: strings["shop_section_skins"],
                            desc: strings["shop_section_skins_desc"],
                            ownedCount: shelves.ownedSkins,
                            totalCount: shelves.skins.count
                        )
                        .id("section-skins")
                        skinGrid(previewSlice(shelves.skins, skinsPreview) { $0.id == vm.skinId },
                                 shelves: shelves, keyPrefix: "front")
                        if shelves.skins.count > skinsPreview {
                            ShelfLink(total: shelves.skins.count) { vm.navigate(.shopShelf(.friends)) }
                        }

                        SectionHeader(
                            title: strings["shop_section_pads"],
                            desc: strings["shop_section_pads_desc"],
                            ownedCount: shelves.ownedPads,
                            totalCount: shelves.pads.count
                        )
                        .id("section-pads")
                        padGrid(previewSlice(shelves.pads, padsPreview) { $0.id == vm.padId },
                                shelves: shelves, keyPrefix: "front")
                        if shelves.pads.count > padsPreview {
                            ShelfLink(total: shelves.pads.count) { vm.navigate(.shopShelf(.pads)) }
                        }

                        SectionHeader(
                            title: strings["shop_section_themes"],
                            desc: strings["shop_section_themes_desc"],
                            ownedCount: shelves.ownedThemes,
                            totalCount: shelves.themes.count
                        )
                        .id("section-themes")
                        themeList(previewSlice(shelves.themes, themesPreview) { $0.id == vm.themeId },
                                  shelves: shelves)
                        if shelves.themes.count > themesPreview {
                            ShelfLink(total: shelves.themes.count) { vm.navigate(.shopShelf(.themes)) }
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
                // DEBUG-only: open the shop already scrolled to one section, so a
                // screenshot run can cover the parts that live below the fold.
                .onAppear {
                    #if DEBUG
                    if let section = ProcessInfo.processInfo.environment["PP_SHOP_SECTION"] {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            proxy.scrollTo("section-\(section)", anchor: .top)
                        }
                    }
                    #endif
                }
                }
            }
            .pondContentWidth()

            purchasingVeil

            if let theme = previewTheme {
                themeDialog(theme, shelves: shelves)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: previewTheme?.id)
        .coinConfirm($pending, coins: vm.coins) { buy in
            if vm.buyWithCoins(price: buy.price, productId: buy.productId) { buy.onGranted() }
        }
        .sheet(isPresented: $showPremiumDetails) {
            PremiumDetailsSheet(
                isPremium: vm.isPremium,
                levelCount: vm.premiumLevelCount(),
                price: vm.price(Catalog.premiumId, fallback: Catalog.premiumPrice),
                onBuy: {
                    showPremiumDetails = false
                    buyForMoney(Catalog.premiumId)
                }
            )
            .environment(\.palette, palette)
            .environment(\.strings, strings)
        }
    }

    @ViewBuilder private var purchasingVeil: some View {
        // Blocks double-taps while the App Store payment sheet is up.
        if vm.purchasing {
            Color.black.opacity(0.25).ignoresSafeArea()
            ProgressView().controlSize(.large).tint(palette.accent)
        }
    }

    /// Full theme try-on: the dialog is re-themed with the candidate palette.
    private func themeDialog(_ theme: ThemeItem, shelves: ShopShelves) -> some View {
        ThemePreviewDialog(
            theme: theme,
            skinId: vm.skinId,
            padId: vm.padId,
            selected: theme.id == vm.themeId,
            usable: shelves.usable(theme.unlock, Catalog.themeProductId(theme.id)),
            affordable: vm.canAfford(theme.unlock.coinPrice ?? 0),
            highestSolved: vm.highestSolvedLevel(),
            onApply: {
                vm.selectTheme(theme.id)
                previewTheme = nil
            },
            onBuy: {
                previewTheme = nil
                // Money and coins are two different confirmations: the App Store
                // sheet is its own, and a coin purchase gets ours.
                if theme.unlock.isMoney {
                    buyForMoney(Catalog.themeProductId(theme.id)) { vm.selectTheme(theme.id) }
                } else {
                    pending = PendingBuy(
                        productId: Catalog.themeProductId(theme.id),
                        name: strings[theme.nameKey],
                        price: theme.unlock.coinPrice ?? 0
                    ) { vm.selectTheme(theme.id) }
                }
            },
            onDismiss: { previewTheme = nil },
            moneyPrice: theme.unlock.isMoney
                ? vm.price(Catalog.themeProductId(theme.id), fallback: nil)
                : nil
        )
        .transition(.opacity)
    }

    /// Runs the App Store payment sheet, which is its own confirmation.
    private func buyForMoney(_ productId: String, onGranted: @escaping () -> Void = {}) {
        Task { if await vm.purchase(productId) { onGranted() } }
    }

    // MARK: Shelves

    @ViewBuilder
    private func skinGrid(_ skins: [SkinItem], shelves: ShopShelves, keyPrefix: String) -> some View {
        gridRows(skins, keyPrefix: keyPrefix + "-skin") { skin in
            let productId = Catalog.skinProductId(skin.id)
            ShopGridCard(
                name: strings[skin.nameKey],
                unlock: skin.unlock,
                selected: skin.id == vm.skinId,
                usable: shelves.usable(skin.unlock, productId),
                affordable: vm.canAfford(skin.unlock.coinPrice ?? 0),
                onSelect: { vm.selectSkin(skin.id) },
                onBuy: {
                    pending = PendingBuy(
                        productId: productId,
                        name: strings[skin.nameKey],
                        price: skin.unlock.coinPrice ?? 0
                    ) { vm.selectSkin(skin.id) }
                }
            ) {
                SkinPreview(skinId: skin.id).aspectRatio(1.35, contentMode: .fit)
            }
        }
    }

    @ViewBuilder
    private func padGrid(_ pads: [PadItem], shelves: ShopShelves, keyPrefix: String) -> some View {
        gridRows(pads, keyPrefix: keyPrefix + "-pad") { pad in
            let productId = Catalog.padProductId(pad.id)
            ShopGridCard(
                name: strings[pad.nameKey],
                unlock: pad.unlock,
                selected: pad.id == vm.padId,
                usable: shelves.usable(pad.unlock, productId),
                affordable: vm.canAfford(pad.unlock.coinPrice ?? 0),
                onSelect: { vm.selectPad(pad.id) },
                onBuy: {
                    pending = PendingBuy(
                        productId: productId,
                        name: strings[pad.nameKey],
                        price: pad.unlock.coinPrice ?? 0
                    ) { vm.selectPad(pad.id) }
                }
            ) {
                PadPreview(padId: pad.id).aspectRatio(1.35, contentMode: .fit)
            }
        }
    }

    @ViewBuilder
    private func themeList(_ themes: [ThemeItem], shelves: ShopShelves) -> some View {
        ForEach(themes) { theme in
            ThemeRow(
                theme: theme,
                selected: theme.id == vm.themeId,
                usable: shelves.usable(theme.unlock, Catalog.themeProductId(theme.id)),
                affordable: vm.canAfford(theme.unlock.coinPrice ?? 0),
                onOpen: { previewTheme = theme }
            )
        }
    }

    /// `keyPrefix` names the grid, because several of these live in one
    /// LazyVStack: keyed by row index alone, the pads' first row and the skins'
    /// first row are the same identity to SwiftUI, and the second grid never
    /// renders at all.
    @ViewBuilder
    private func gridRows<Item: Identifiable, Card: View>(
        _ items: [Item], keyPrefix: String, @ViewBuilder card: @escaping (Item) -> Card
    ) -> some View {
        let rows = stride(from: 0, to: items.count, by: 3).map { Array(items[$0..<min($0 + 3, items.count)]) }
        ForEach(Array(rows.enumerated()), id: \.offset) { index, rowItems in
            HStack(alignment: .top, spacing: 10) {
                ForEach(rowItems) { item in
                    card(item).frame(maxWidth: .infinity)
                }
                ForEach(0..<(3 - rowItems.count), id: \.self) { _ in
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
            .id("\(keyPrefix)-row-\(index)")
        }
    }
}

/// What both shop pages need: what is on sale, and the one rule deciding
/// whether a thing is usable. Gathered in one place so the front page and a
/// shelf page can never disagree about what the player owns.
struct ShopShelves {
    let themes: [ThemeItem]
    let skins: [SkinItem]
    let pads: [PadItem]
    let usable: (Unlock, String) -> Bool

    let ownedThemes: Int
    let ownedSkins: Int
    let ownedPads: Int

    @MainActor
    init(vm: AppViewModel) {
        // Premium exclusives only join the shelves once premium is owned;
        // before that they live inside the premium card's detail view.
        let premium = vm.isPremium
        themes = Catalog.themes.filter { premium || !$0.unlock.isPremium }
        skins = Catalog.skins.filter { premium || !$0.unlock.isPremium }
        pads = Catalog.pads.filter { premium || !$0.unlock.isPremium }
        // The same rule the pond roster uses, deliberately: a friend earned on
        // the golden-pond ladder is owned, and a shelf that asked for coins for
        // it anyway would charge twice for one thing.
        usable = { unlock, productId in vm.isOwned(unlock, productId: productId) }
        ownedThemes = themes.count { vm.isOwned($0.unlock, productId: Catalog.themeProductId($0.id)) }
        ownedSkins = skins.count { vm.isOwned($0.unlock, productId: Catalog.skinProductId($0.id)) }
        ownedPads = pads.count { vm.isOwned($0.unlock, productId: Catalog.padProductId($0.id)) }
    }
}

/// One shelf on its own page - every friend, pad or theme in the catalog. The
/// shop's front page keeps a taster of each and sends the rest here, which is
/// what stops a 36-item catalog from burying the two shelves under it.
/// How you get a thing - and which tab of a shelf page you find it on.
///
/// Sixty-nine friends is too many for one page whatever order they are in. The
/// first cut was labelled sections down one scroll and it was still a long way
/// to the bottom; the second was a tab per unlock kind, which put "Bought with
/// coins", "Daily streak" and "Golden ponds" side by side as three tabs that
/// mean the same thing to a player - *something you work toward*.
///
/// So there are five, they are one word each, and they carry an SF Symbol:
/// **Yours** (a lens over everything already owned, wherever it came from),
/// **Play**, **Earn** - coins, streaks and golden ponds together, with each card
/// saying what it in particular takes - **Themes**, and **Legends**. Premium
/// appears only once it is owned, because until then its items are not on the
/// shelf. The same five serve the lily pads, which simply have fewer of them.
enum ShelfGroup: String, CaseIterable, Identifiable {
    case owned, play, earn, themes, legends, premium

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .owned: return "shelf_tab_yours"
        case .play: return "shelf_tab_play"
        case .earn: return "shelf_tab_earn"
        case .themes: return "shelf_tab_themes"
        case .legends: return "shelf_tab_legends"
        case .premium: return "shelf_tab_premium"
        }
    }

    var descKey: String {
        switch self {
        case .owned: return "shelf_desc_yours"
        case .play: return "shelf_desc_play"
        case .earn: return "shelf_desc_earn"
        case .themes: return "friends_theme_hint"
        case .legends: return "friends_special_hint"
        case .premium: return "shelf_desc_premium"
        }
    }

    var symbol: String {
        switch self {
        case .owned: return "checkmark.circle.fill"
        case .play: return "star.fill"
        case .earn: return "gift.fill"
        case .themes: return "paintpalette.fill"
        case .legends: return "sparkles"
        case .premium: return "crown.fill"
        }
    }

    /// `owned` decides the Yours tab and nothing else: every other tab shows its
    /// whole route whether the items are owned or not, so a tab does not shrink
    /// as you buy from it and its count means "how many exist this way".
    func holds(_ unlock: Unlock, owned: Bool) -> Bool {
        switch self {
        case .owned: return owned
        // Free and level rewards share a tab: both are "you played for this",
        // and a tab holding only the one starting item is a tab for nothing.
        case .play: return unlock.isFree || unlock.rewardLevel != nil
        // The three long climbs, together. They are different ladders but the
        // same answer to "how do I get that?" - keep at it. Each card still
        // says which ladder it is on.
        case .earn:
            return unlock.coinPrice != nil || unlock.rewardBonusPonds != nil || unlock.rewardStreak != nil
        case .themes: return unlock.themeFriendOf != nil
        case .legends: return unlock.isMoney
        case .premium: return unlock.isPremium
        }
    }
}

/// One tab: an SF Symbol, one word, and how many are behind it.
///
/// The symbol is what stops five one-word labels reading as a row of buttons -
/// with it, the row is scannable without being read, which is the whole reason
/// the labels could be cut to one word in the first place.
struct ShelfTabChip: View {
    let group: ShelfGroup
    let count: Int
    let selected: Bool
    let action: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: group.symbol)
                    .font(.system(size: 15, weight: .semibold))
                HStack(spacing: 5) {
                    Text(strings[group.titleKey])
                        .font(.game(13, .bold))
                    Text("\(count)")
                        .font(.game(11, .bold))
                        .opacity(0.6)
                }
            }
            .foregroundStyle(selected ? PondPalette.onAccent : palette.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? palette.accent : palette.surface,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

struct ShopShelfView: View {
    @ObservedObject var vm: AppViewModel
    let shelf: Shelf
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings

    @State private var previewTheme: ThemeItem?
    @State private var pending: PendingBuy?
    /// Which tab of a tabbed shelf is open. Themes have no tabs - twelve
    /// full-width rows read fine as a list, and tabs are a cost that only pays
    /// above about thirty things.
    @State private var tab: ShelfGroup = .owned

    var body: some View {
        let shelves = ShopShelves(vm: vm)
        let tabbed = shelf != .themes
        // One list of (unlock, owned) pairs, so the grouping never has to know
        // which shelf it is looking at.
        let entries: [(Unlock, Bool)] = {
            switch shelf {
            case .friends:
                return shelves.skins.map { ($0.unlock, shelves.usable($0.unlock, Catalog.skinProductId($0.id))) }
            case .pads:
                return shelves.pads.map { ($0.unlock, shelves.usable($0.unlock, Catalog.padProductId($0.id))) }
            case .themes:
                return []
            }
        }()
        let groups = ShelfGroup.allCases.filter { g in entries.contains { g.holds($0.0, owned: $0.1) } }
        let current = groups.contains(tab) ? tab : (groups.first ?? .play)
        let titleKey: String
        let descKey: String
        let owned: Int
        let total: Int
        switch shelf {
        case .friends:
            titleKey = "shop_section_skins"
            descKey = current.descKey
            let shown = shelves.skins.filter {
                current.holds($0.unlock, owned: shelves.usable($0.unlock, Catalog.skinProductId($0.id)))
            }
            owned = shown.count { shelves.usable($0.unlock, Catalog.skinProductId($0.id)) }
            total = shown.count
        case .pads:
            titleKey = "shop_section_pads"
            descKey = current.descKey
            let shown = shelves.pads.filter {
                current.holds($0.unlock, owned: shelves.usable($0.unlock, Catalog.padProductId($0.id)))
            }
            owned = shown.count { shelves.usable($0.unlock, Catalog.padProductId($0.id)) }
            total = shown.count
        case .themes:
            titleKey = "shop_section_themes"; descKey = "shop_section_themes_desc"
            owned = shelves.ownedThemes; total = shelves.themes.count
        }

        return ZStack {
            VStack(spacing: 0) {
                ScreenHeader(title: strings[titleKey], onBack: { vm.back() }) {
                    CoinChip(coins: vm.coins)
                }
                if tabbed {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(groups) { group in
                                ShelfTabChip(
                                    group: group,
                                    count: entries.count { group.holds($0.0, owned: $0.1) },
                                    selected: group == current
                                ) { tab = group }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 6)
                }
                ScrollView {
                    LazyVStack(spacing: 10) {
                        // A shelf page's own subtitle and tally; the title is
                        // already in the bar.
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(strings[descKey])
                                .font(.game(12))
                                .foregroundStyle(palette.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Text(strings["shop_count", owned, total])
                                .font(.game(13, .semibold))
                                .foregroundStyle(palette.textSecondary)
                                .fixedSize()
                        }
                        .padding(.top, 4)

                        switch shelf {
                        case .friends: shelfSkins(shelves, group: current)
                        case .pads: shelfPads(shelves, group: current)
                        case .themes: shelfThemes(shelves)
                        }
                        if total == 0 {
                            Text(strings["shelf_empty"])
                                .font(.game(13))
                                .foregroundStyle(palette.textSecondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        }

                        Text(strings["shop_note"])
                            .font(.game(12))
                            .foregroundStyle(palette.textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 10)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .pondContentWidth()

            if let theme = previewTheme {
                ThemePreviewDialog(
                    theme: theme,
                    skinId: vm.skinId,
                    padId: vm.padId,
                    selected: theme.id == vm.themeId,
                    usable: shelves.usable(theme.unlock, Catalog.themeProductId(theme.id)),
                    affordable: vm.canAfford(theme.unlock.coinPrice ?? 0),
                    highestSolved: vm.highestSolvedLevel(),
                    onApply: {
                        vm.selectTheme(theme.id)
                        previewTheme = nil
                    },
                    onBuy: {
                        previewTheme = nil
                        if theme.unlock.isMoney {
                            buyForMoney(Catalog.themeProductId(theme.id))
                        } else {
                            pending = PendingBuy(
                                productId: Catalog.themeProductId(theme.id),
                                name: strings[theme.nameKey],
                                price: theme.unlock.coinPrice ?? 0
                            ) { vm.selectTheme(theme.id) }
                        }
                    },
                    onDismiss: { previewTheme = nil },
                    moneyPrice: theme.unlock.isMoney
                        ? vm.price(Catalog.themeProductId(theme.id), fallback: nil)
                        : nil
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: previewTheme?.id)
        .coinConfirm($pending, coins: vm.coins) { buy in
            if vm.buyWithCoins(price: buy.price, productId: buy.productId) { buy.onGranted() }
        }
    }

    /// StoreKit's own sheet is the confirmation, so this hands straight to it.
    private func buyForMoney(_ productId: String) {
        Task { _ = await vm.purchase(productId) }
    }

    @ViewBuilder private func shelfSkins(_ shelves: ShopShelves, group: ShelfGroup) -> some View {
        let shown = shelves.skins.filter {
            group.holds($0.unlock, owned: shelves.usable($0.unlock, Catalog.skinProductId($0.id)))
        }
        gridRows(shown) { skin in
            let productId = Catalog.skinProductId(skin.id)
            ShopGridCard(
                name: strings[skin.nameKey],
                unlock: skin.unlock,
                selected: skin.id == vm.skinId,
                usable: shelves.usable(skin.unlock, productId),
                affordable: vm.canAfford(skin.unlock.coinPrice ?? 0),
                onSelect: { vm.selectSkin(skin.id) },
                onBuy: {
                    if skin.unlock.isMoney {
                        // Money goes straight to StoreKit's own sheet, which is
                        // the confirmation - asking "are you sure?" first is two
                        // dialogs for one decision.
                        buyForMoney(productId)
                    } else {
                        pending = PendingBuy(productId: productId, name: strings[skin.nameKey],
                                             price: skin.unlock.coinPrice ?? 0) { vm.selectSkin(skin.id) }
                    }
                },
                moneyPrice: skin.unlock.isMoney ? vm.price(productId, fallback: nil) : nil,
                onOpenTheme: { previewTheme = Catalog.themeOfFriend(skin) }
            ) { SkinPreview(skinId: skin.id).aspectRatio(1.35, contentMode: .fit) }
        }
    }

    @ViewBuilder private func shelfPads(_ shelves: ShopShelves, group: ShelfGroup) -> some View {
        let shown = shelves.pads.filter {
            group.holds($0.unlock, owned: shelves.usable($0.unlock, Catalog.padProductId($0.id)))
        }
        gridRows(shown) { pad in
            let productId = Catalog.padProductId(pad.id)
            ShopGridCard(
                name: strings[pad.nameKey],
                unlock: pad.unlock,
                selected: pad.id == vm.padId,
                usable: shelves.usable(pad.unlock, productId),
                affordable: vm.canAfford(pad.unlock.coinPrice ?? 0),
                onSelect: { vm.selectPad(pad.id) },
                onBuy: {
                    pending = PendingBuy(productId: productId, name: strings[pad.nameKey],
                                         price: pad.unlock.coinPrice ?? 0) { vm.selectPad(pad.id) }
                }
            ) { PadPreview(padId: pad.id).aspectRatio(1.35, contentMode: .fit) }
        }
    }

    @ViewBuilder private func shelfThemes(_ shelves: ShopShelves) -> some View {
        ForEach(shelves.themes) { theme in
            ThemeRow(
                theme: theme,
                selected: theme.id == vm.themeId,
                usable: shelves.usable(theme.unlock, Catalog.themeProductId(theme.id)),
                affordable: vm.canAfford(theme.unlock.coinPrice ?? 0),
                onOpen: { previewTheme = theme }
            )
        }
    }

    @ViewBuilder
    private func gridRows<Item: Identifiable, Card: View>(
        _ items: [Item], @ViewBuilder card: @escaping (Item) -> Card
    ) -> some View {
        let rows = stride(from: 0, to: items.count, by: 3).map { Array(items[$0..<min($0 + 3, items.count)]) }
        ForEach(Array(rows.enumerated()), id: \.offset) { index, rowItems in
            HStack(alignment: .top, spacing: 10) {
                ForEach(rowItems) { item in card(item).frame(maxWidth: .infinity) }
                ForEach(0..<(3 - rowItems.count), id: \.self) { _ in
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
            .id("shelf-row-\(index)")
        }
    }
}

/// The coin purchase confirmation, shared by both shop pages.
private extension View {
    func coinConfirm(
        _ pending: Binding<PendingBuy?>, coins: Int, onConfirm: @escaping (PendingBuy) -> Void
    ) -> some View {
        modifier(CoinConfirmModifier(pending: pending, coins: coins, onConfirm: onConfirm))
    }
}

private struct CoinConfirmModifier: ViewModifier {
    @Environment(\.strings) private var strings
    @Binding var pending: PendingBuy?
    let coins: Int
    let onConfirm: (PendingBuy) -> Void

    func body(content: Content) -> some View {
        content.alert(
            pending.map { strings["shop_buy_title", $0.name] } ?? "",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }),
            presenting: pending
        ) { buy in
            Button(strings["shop_buy_confirm"]) { onConfirm(buy) }
            Button(strings["shop_cancel"], role: .cancel) {}
        } message: { buy in
            Text(buy.price > 0 && !FreeMode.enabled
                ? strings["shop_buy_coins_body", buy.price, coins]
                : strings["shop_buy_body"])
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

/// Hints, sold two ways: five for coins, or fifty for money. Premium owners
/// never see it - their hints are unlimited.
private struct HintPackCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let hintsLeft: Int
    let affordable: Bool
    let packPrice: String
    let onBuyWithCoins: () -> Void
    let onBuyPack: () -> Void

    var body: some View {
        let bundlePrice = CoinBank.hintBundle * CoinBank.priceHint
        VStack(spacing: 10) {
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
            }
            HStack(spacing: 8) {
                Button(action: onBuyWithCoins) {
                    HStack(spacing: 8) {
                        Text(strings["shop_hints_bundle", CoinBank.hintBundle])
                            .font(.game(13, .semibold))
                            .foregroundStyle(palette.textPrimary)
                        CoinPrice(price: bundlePrice, affordable: affordable)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(palette.surfaceHigh, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(SquishyButtonStyle())
                .disabled(!affordable)
                .opacity(affordable ? 1 : 0.5)

                Button(action: onBuyPack) {
                    HStack(spacing: 8) {
                        Text(strings["shop_hints_pack", Catalog.hintsPerPack])
                            .font(.game(13, .semibold))
                            .foregroundStyle(palette.textPrimary)
                        Text(packPrice)
                            .font(.game(13, .bold))
                            .foregroundStyle(palette.accent)
                    }
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(palette.surfaceHigh, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(SquishyButtonStyle())
            }
        }
        .padding(14)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.top, 10)
    }
}

/// The coin packs - the one place money buys coins.
///
/// It sits under the hint card rather than at the top of the shop on purpose.
/// Coins are meant to arrive by playing; this card is for someone who has
/// already decided they want a particular friend today, not the first thing the
/// shop asks of a visitor.
///
/// Android keeps these shut outside a debug build because Play Billing is not
/// wired there yet and a free 500-coin pack would buy the whole catalogue.
/// StoreKit *is* wired here, so on iOS they are simply open.
private struct CoinPacksCard: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let coins: Int
    let priceOf: (String, String) -> String
    let onBuy: (String) -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                CoinIcon(size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings["shop_section_coins"])
                        .font(.game(15, .bold))
                        .foregroundStyle(palette.textPrimary)
                    Text(strings["shop_section_coins_desc", coins])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
            }
            HStack(spacing: 8) {
                ForEach(Array(CoinBank.coinPacks.enumerated()), id: \.offset) { index, amount in
                    let productId = Catalog.coinPackIds[index]
                    Button { onBuy(productId) } label: {
                        VStack(spacing: 4) {
                            CoinIcon(size: 22)
                            Text("\(amount)")
                                .font(.game(15, .bold))
                                .foregroundStyle(palette.textPrimary)
                            Text(priceOf(productId, Catalog.coinPackPrices[index]))
                                .font(.game(11, .semibold))
                                .foregroundStyle(palette.accent)
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(palette.surfaceHigh, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(SquishyButtonStyle())
                }
            }
        }
        .padding(14)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.top, 10)
    }
}

/// The one tap that opens a shelf's own page, sitting under its taster rows.
private struct ShelfLink: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let total: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(strings["shop_show_all", total])
                    .font(.game(14, .bold))
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(palette.accent)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(SquishyButtonStyle())
        .padding(.top, 8)
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
    let affordable: Bool
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
                } else if let count = theme.unlock.rewardBonusPonds {
                    Text(strings["bonus_locked_shop", count])
                        .font(.game(13, .semibold))
                        .foregroundStyle(palette.textSecondary)
                } else if let days = theme.unlock.rewardStreak {
                    Text(strings["collection_streak_lock", days])
                        .font(.game(13, .semibold))
                        .foregroundStyle(palette.textSecondary)
                } else if let price = theme.unlock.coinPrice {
                    CoinPrice(price: price, affordable: affordable)
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
    var affordable: Bool = true
    let onSelect: () -> Void
    let onBuy: () -> Void
    /// StoreKit's own formatted price, or nil while a special friend cannot be
    /// bought. A card with no price never responds to a tap: an app that hands
    /// over a paid friend because the store was unreachable is worse than one
    /// that says "Unavailable".
    var moneyPrice: String?
    /// Where a locked theme friend sends you: to its theme, which is the only
    /// place it can actually be got.
    var onOpenTheme: (() -> Void)?
    @ViewBuilder let preview: Preview

    private var buyable: Bool { unlock.coinPrice != nil }
    private var moneyBuyable: Bool { unlock.isMoney && moneyPrice != nil }

    var body: some View {
        Button {
            if selected {
                // already equipped
            } else if usable {
                onSelect()
            } else if buyable && affordable {
                // A card you cannot afford does nothing rather than opening a
                // dialog whose only button is disabled.
                onBuy()
            } else if moneyBuyable {
                onBuy()
            } else if unlock.themeFriendOf != nil {
                // Not for sale here at all: the only door is its theme.
                onOpenTheme?()
            }
        } label: {
            VStack(spacing: 6) {
                preview
                    .overlay {
                        if !usable, !buyable, !unlock.isMoney, !unlock.isFree {
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
                if !usable, unlock.isMoney {
                    Text(moneyPrice ?? strings["shop_price_unavailable"])
                        .font(.game(13, .bold))
                        .foregroundStyle(moneyPrice == nil ? palette.textSecondary : palette.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else if !usable, case .coins(let price, let bonusCount) = unlock {
                    CoinPrice(price: price, affordable: affordable)
                    // The second door to it. Worth saying out loud: without this
                    // the golden-pond ladder is invisible to anyone reading the
                    // shelf, and it is the whole reason to go and play one.
                    if let bonusCount {
                        Text(strings["shop_or_bonus", bonusCount])
                            .font(.game(10))
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text(caption)
                        .font(.game(11))
                        .foregroundStyle(selected ? palette.accent : palette.textSecondary)
                }
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
        if let count = unlock.rewardBonusPonds { return strings["bonus_locked_shop", count] }
        if let days = unlock.rewardStreak { return strings["collection_streak_lock", days] }
        // The theme's name, not the whole sentence: the tab groups these under a
        // header that already says "comes with the Jungle Mist theme", and
        // repeating it on both cards makes each one three lines tall.
        if let themeId = unlock.themeFriendOf {
            return strings[Catalog.themes.first { $0.id == themeId }?.nameKey ?? ""]
        }
        return ""
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
    let affordable: Bool
    let highestSolved: Int
    let onApply: () -> Void
    let onBuy: () -> Void
    let onDismiss: () -> Void
    /// The App Store price, when this is a theme money buys. Nil while StoreKit
    /// is still answering, which is also the signal not to offer the button:
    /// a buy button with no price on it is a button nobody should press.
    var moneyPrice: String?

    var body: some View {
        let palette = theme.palette
        let friends = Catalog.friendsOfTheme(theme.id)
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

                // The pair that comes with it. A theme friend has no other door
                // - no price, no level, no golden pond - so the only place
                // anyone can find out that buying the theme also buys two
                // friends is here, on the theme.
                if !friends.isEmpty {
                    VStack(spacing: 6) {
                        Text(strings["shop_theme_friends"])
                            .font(.game(12, .semibold))
                            .foregroundStyle(palette.textSecondary)
                        HStack(spacing: 14) {
                            ForEach(friends) { friend in
                                VStack(spacing: 4) {
                                    SkinPreview(skinId: friend.id)
                                        .frame(width: 46, height: 46)
                                    Text(strings[friend.nameKey])
                                        .font(.game(11))
                                        .foregroundStyle(palette.textSecondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(maxWidth: 92)
                            }
                        }
                    }
                    .padding(.top, 14)
                }

                Group {
                    if selected {
                        GhostButton(strings["close"], action: onDismiss)
                    } else if usable {
                        PrimaryButton(strings["shop_preview_use"], action: onApply)
                    } else if theme.unlock.isMoney {
                        // Same rule as the paid friends: no price, no button.
                        // The store being unreachable is a thing to say, not a
                        // thing to spin about.
                        VStack(spacing: 8) {
                            Text(moneyPrice ?? strings["shop_price_unavailable"])
                                .font(.game(16, .bold))
                                .foregroundStyle(moneyPrice == nil ? palette.textSecondary : palette.accent)
                            if moneyPrice != nil {
                                PrimaryButton(strings["shop_buy_confirm"], action: onBuy)
                            }
                        }
                    } else if let price = theme.unlock.coinPrice {
                        // The price is always shown; the button only appears
                        // when it can actually be paid, so the dialog never ends
                        // in a button that refuses.
                        VStack(spacing: 8) {
                            CoinPrice(price: price, affordable: affordable)
                            if affordable {
                                PrimaryButton(strings["shop_buy_confirm"], action: onBuy)
                            }
                        }
                    } else if let days = theme.unlock.rewardStreak {
                        Text(strings["collection_streak_lock", days])
                            .font(.game(14))
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)
                    } else if let level = theme.unlock.rewardLevel {
                        Text(strings["shop_reward_unlock_at", level, highestSolved])
                            .font(.game(14))
                            .foregroundStyle(palette.textSecondary)
                            .multilineTextAlignment(.center)
                    } else if let count = theme.unlock.rewardBonusPonds {
                        Text(strings["bonus_locked_shop", count])
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
    let equipped: Bool
    let onEquip: () -> Void
    /// A lily pad is not a friend and does not "join your pond", so the heading
    /// and the sentence under it both follow what was actually won.
    var titleKey = "win_reward_title"
    var bodyKey = "win_reward_body"
    var actionKey = "win_reward_equip"
    @ViewBuilder let preview: Preview

    var body: some View {
        HStack(spacing: 10) {
            preview
            VStack(alignment: .leading, spacing: 2) {
                Text(strings[titleKey])
                    .font(.game(14, .bold))
                    .foregroundStyle(palette.accent)
                Text(strings[bodyKey, name])
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            if equipped {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.accent)
                    Text(strings["win_reward_equipped"])
                        .font(.game(13, .semibold))
                        .foregroundStyle(palette.textSecondary)
                }
            } else {
                Button(strings[actionKey], action: onEquip)
                    .font(.game(13, .bold))
                    .foregroundStyle(palette.accent)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// A decoration on a patch of its own water - the win card's prize thumbnail.
struct DecorPreview: View {
    @Environment(\.palette) private var palette
    let item: PondCatalog.Decor

    var body: some View {
        Canvas { ctx, size in
            drawRoundRectPatch(&ctx, size: size, palette: palette)
            let side = min(size.width, size.height) * 0.82
            let rect = CGRect(
                x: (size.width - side) / 2, y: (size.height - side) / 2,
                width: side, height: side
            )
            drawDecor(&ctx, id: item.id, rect: rect, palette: palette, phase: 0.7)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
