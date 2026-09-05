//
//  AppViewModel.swift
//  PondPulse
//
//  App-wide state and navigation, ported from the Android ui/AppViewModel.kt.
//  Android's StateFlows become @Published values that write through the
//  UserDefaults-backed ProgressStore.
//

import Combine
import CoreGraphics
import SwiftUI

/// The three things the shop sells, each of which owns a page.
enum Shelf: Hashable {
    case friends, pads, themes
}

enum Screen: Equatable {
    case home
    /// The gallery of packs.
    case packs
    /// One pack's ponds. `focusLevelId`, when set, is the pond to open the pager
    /// on - set when leaving for a level, so backing out of level 5 returns to
    /// the page level 5 is on rather than to wherever the player's progress has
    /// since reached.
    case packLevels(packId: String, focusLevelId: String? = nil)
    case game(levelId: String)
    case settings
    case shop
    case rush

    /// One shop shelf on its own page, reached from the shop's "Show all".
    case shopShelf(Shelf)

    /// Today's one pond, the same for everybody, played for a streak.
    case daily

    /// "My Pond": the full-screen pond where the friends you own actually live.
    ///
    /// It absorbed the old Collection screen, which showed the same friends as a
    /// scrolling roster with a small pond glued to the top. Two screens about the
    /// same thing meant the pond was always the decorative one; now the pond is
    /// the screen and the roster is a panel inside it.
    case pond

    /// One of the pond's four games, played on its own.
    case pondGame(gameId: String)

    /// Arranging the pond: the shelf of decorations, and the pond you drag them
    /// onto. Its own screen rather than a panel over My Pond, because a panel
    /// covers the half of the pond you are trying to place something on.
    case decorate

    /// Quests: today's three, and the nine long ladders under them.
    ///
    /// Its own screen rather than a panel in My Pond because most of it is about
    /// the campaign, the daily and Splash Rush - none of which happen in the
    /// pond - and because a board you can only reach through a pond you have not
    /// opened yet is a board a new player never sees.
    case quests

    /// One ladder, rung by rung: what is behind you, what you are on, and every
    /// step still to come.
    ///
    /// A second screen rather than an expanding row, because the whole reason
    /// the shelf is nine rows now is that nine rows fit on a phone - and a row
    /// that unfolds into eleven puts the shelf straight back where it was.
    /// Carries the family's raw value so `Screen` stays `Equatable` without
    /// `Achievements` having to be.
    case questLadder(String)
}

@MainActor
final class AppViewModel: ObservableObject {

    private let store = ProgressStore()
    private let storeManager = StoreManager()

    @Published private(set) var haptics: Bool
    @Published private(set) var stars: [String: Int]
    @Published private(set) var rushBests: [Int: Int]
    @Published private(set) var owned: Set<String>
    @Published private(set) var themeId: String
    @Published private(set) var skinId: String
    @Published private(set) var padId: String
    /// Hints as stored. Read `hintsLeft`, which folds in the tester top-up.
    @Published private(set) var hintsStored: Int
    @Published private(set) var hintedLevels: Set<String>
    /// In-app language override; nil follows the device language.
    @Published private(set) var languageOverride: Language?

    /// Developer tools: the level skipper in the pond. Only settable from a
    /// debug build, so it is always false in anything that reaches a player.
    @Published private(set) var debugTools: Bool

    /// Whether the tester has switched "Unlock everything" on. Settable in a
    /// debug build, and in a closed-testing one; nowhere else.
    @Published private(set) var unlockAllFlag: Bool

    /// Hints in hand.
    ///
    /// "Unlock everything" tops the counter up rather than leaning on the
    /// premium upgrade it also grants: premium reads as "Unlimited" inside a
    /// pond, but the shop still quotes a number, and a tester who cannot see
    /// the hint count going up cannot test hints. Shown, never banked - the
    /// stored half is untouched, so turning the switch off puts the honest
    /// number straight back.
    var hintsLeft: Int { hintsStored + (unlockAllFlag ? FreeMode.debugHints : 0) }

    // Coins ------------------------------------------------------------------
    @Published private(set) var coinsGranted: Int
    @Published private(set) var coinsSpent: Int
    /// The day the first-clear bonus was last paid. Published because the home
    /// screen offers the bonus until it is taken.
    @Published private(set) var firstClearDay: Int

    // The pond ---------------------------------------------------------------
    @Published private(set) var pondWeather: String
    @Published private(set) var pondWater: String
    @Published private(set) var pondShore: String
    @Published private(set) var pondLayouts: [PondLayout]
    @Published private(set) var pondSlots: Int
    @Published private(set) var layoutSlots: Int
    @Published private(set) var pondFriends: [String]
    @Published private(set) var decorSpots: [String: CGPoint]
    @Published private(set) var decorStored: Set<String>
    @Published private(set) var miniBests: [String: Int]
    @Published private(set) var pondWeekStamp: Int
    @Published private(set) var pondWeekTotal: Int
    /// Today's quest counters, republished on every bump so the board's bars
    /// move while you are looking at them.
    @Published private(set) var questCounters = Quests.Counters()
    @Published private(set) var questPaid: Set<String> = []

    // The daily pond ---------------------------------------------------------
    @Published private(set) var dailyLastDay: Int
    @Published private(set) var dailyStreakStored: Int
    @Published private(set) var dailyBestStreak: Int
    @Published private(set) var dailyTotal: Int

    /// App Store localized prices by product id; Catalog's display prices are
    /// the fallback until the store answers (or when it can't).
    @Published private(set) var prices: [String: String] = [:]
    /// True while a payment sheet is up, so the shop blocks double-taps.
    @Published private(set) var purchasing = false

    @Published var backStack: [Screen] = [.home]

    init() {
        // Before a single coin is read: a save from before the ×10 rescale
        // holds totals a tenth of the size the prices now expect.
        store.migrateEconomy()
        haptics = store.haptics
        stars = store.stars
        rushBests = store.rushBests
        owned = store.owned
        themeId = store.selectedTheme
        skinId = store.selectedSkin
        padId = store.selectedPad
        hintsStored = store.hintsLeft
        hintedLevels = store.hintedLevels
        languageOverride = store.language
        debugTools = store.debugTools
        unlockAllFlag = store.unlockAll
        coinsGranted = store.coinsGranted
        coinsSpent = store.coinsSpent
        firstClearDay = store.firstClearDay
        pondWeather = store.pondWeather
        pondWater = store.pondWater
        pondShore = store.pondShore
        pondLayouts = store.pondLayouts
        pondSlots = store.pondSlots
        layoutSlots = store.layoutSlots
        pondFriends = store.pondFriends
        decorSpots = store.decorSpots
        decorStored = store.decorStored
        miniBests = store.miniBests
        pondWeekStamp = store.pondWeek
        pondWeekTotal = store.pondWeekEarned
        questCounters = store.questCounters(day: currentEpochDay())
        questPaid = store.questPaid(day: currentEpochDay())
        dailyLastDay = store.dailyLastDay
        dailyStreakStored = store.dailyStreak
        dailyBestStreak = store.dailyBestStreak
        dailyTotal = store.dailyTotal

        // Settled here rather than only on the events that move the counters: a
        // quest can be finished by the very last thing done before the app is
        // killed, and a payout that only ever happens on the way *in* to a
        // counter would lose that one for good. Cheap, and idempotent - a rung
        // already written down in `questPaid` is never paid twice.
        settleQuests()
        applyDebugLaunchOverrides()

        // Verified App Store outcomes flow back into the persisted state.
        storeManager.onEntitled = { [weak self] productId in self?.grant(productId) }
        storeManager.onRevoked = { [weak self] productId in self?.revoke(productId) }
        storeManager.onHintsPurchased = { [weak self] count in self?.creditHints(count) }
        storeManager.onCoinsPurchased = { [weak self] amount in self?.creditCoins(amount) }
        Task { [weak self] in
            await self?.storeManager.load()
            self?.prices = self?.storeManager.displayPrices ?? [:]
            // What the App Store says was bought, as a floor under the local
            // receipt: a pack bought by a build that predates the receipt would
            // otherwise be a pack a reset forgot about.
            if let bought = await self?.storeManager.purchasedCoinTotal() {
                self?.store.syncCoinsBought(atLeast: bought)
            }
        }
    }

    /// DEBUG-only launch overrides, the twin of Android's `pp_*` intent extras:
    /// `PP_START_LEVEL=<n>` jumps into a level, `PP_START_PACK=pack3` opens one
    /// pack's ponds, `PP_START_SCREEN=packs|shop|rush|daily|pond|decorate|settings|friends|pads|themes|quests[:ladder]`
    /// opens a screen, `PP_START_GAME=chain|herd|seek|target` opens a mini game,
    /// `PP_START_BONUS=b-1` opens a golden pond, and `PP_PREMIUM=1` grants
    /// premium in memory. Passed via `SIMCTL_CHILD_*`; never affects a normal
    /// launch, and never persisted.
    private func applyDebugLaunchOverrides() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        if env["PP_PREMIUM"] != nil {
            owned.insert(Catalog.premiumId)
        }
        if env["PP_COINS"] != nil {
            // In memory only: a balance to shop with, without a StoreKit sheet.
            coinsGranted += Int(env["PP_COINS"] ?? "") ?? 5000
        }
        if let raw = env["PP_START_LEVEL"], let n = Int(raw), (1...Levels.all.count).contains(n) {
            backStack = [.home, .game(levelId: Levels.all[n - 1].id)]
        } else if let packId = env["PP_START_PACK"],
                  Levels.packs.contains(where: { $0.id == packId }) {
            backStack = [.home, .packs, .packLevels(packId: packId)]
        } else if let id = env["PP_START_BONUS"],
                  Levels.bonusPonds.contains(where: { $0.id == id }) {
            backStack = [.home, .game(levelId: id)]
        } else if let id = env["PP_START_GAME"], PondCatalog.gameById(id) != nil {
            backStack = [.home, .pond, .pondGame(gameId: id)]
        } else if let screen = env["PP_START_SCREEN"] {
            switch screen {
            case "packs": backStack = [.home, .packs]
            case "shop": backStack = [.home, .shop]
            case "friends": backStack = [.home, .shop, .shopShelf(.friends)]
            case "pads": backStack = [.home, .shop, .shopShelf(.pads)]
            case "themes": backStack = [.home, .shop, .shopShelf(.themes)]
            case "rush": backStack = [.home, .rush]
            case "daily": backStack = [.home, .daily]
            // "collection" still works: it was this screen's old name, and the
            // screenshot scripts that use it predate the pond absorbing it.
            case "pond", "collection": backStack = [.home, .pond]
            case "decorate": backStack = [.home, .pond, .decorate]
            case "settings": backStack = [.home, .settings]
            case "quests", "achievements": backStack = [.home, .quests]
            default:
                // "quests:stars" opens one ladder, the same way PP_START_PACK
                // opens one pack.
                if screen.hasPrefix("quests:"),
                   let family = Achievements.Family(rawValue: String(screen.dropFirst(7))) {
                    backStack = [.home, .quests, .questLadder(family.rawValue)]
                }
            }
        }
        #endif
    }

    var totalStars: Int { stars.values.reduce(0, +) }

    /// Whether the premium upgrade is in hand.
    ///
    /// Asked of the *effective* set, not the raw one: "Unlock everything" folds
    /// premium in like every other product, and a tester who has it on but is
    /// still shown a locked pond, a hint counter and a card selling premium has
    /// not unlocked everything. Spelled out rather than built as a set union,
    /// because this is read on nearly every screen.
    var isPremium: Bool {
        owned.contains(Catalog.premiumId) || unlockAllFlag || FreeMode.enabled
    }

    var palette: PondPalette { Catalog.themeById(themeId).palette }

    var language: Language { languageOverride ?? .deviceDefault() }

    var strings: Strings { Strings(language: language) }

    /// Everything the player owns, with the free-mode grants folded in.
    ///
    /// Neither fold is ever written back to storage. The second is inert on a
    /// release build, where `FreeMode.enabled` is false; the first is what
    /// "Unlock everything" hands a tester, and the token in it is what answers
    /// for the items that are earned rather than bought - see `isOwned`.
    var effectiveOwned: Set<String> {
        if unlockAllFlag {
            return owned.union(Self.everyProductId).union([FreeMode.unlockAllToken])
        }
        if FreeMode.enabled { return owned.union([Catalog.premiumId]) }
        return owned
    }

    // MARK: - Navigation

    var current: Screen { backStack.last ?? .home }

    func navigate(_ screen: Screen) {
        backStack.append(screen)
    }

    func replaceTop(_ screen: Screen) {
        backStack[backStack.count - 1] = screen
    }

    /// Drops every screen and stands the player on the pond's front door.
    ///
    /// A reset leaves the screens underneath describing a game that no longer
    /// exists - a pack page of solved ponds, a shop shelf of owned friends - so
    /// walking back through them afterwards is walking through ghosts.
    func goHome() {
        backStack = [.home]
    }

    @discardableResult
    func back() -> Bool {
        guard backStack.count > 1 else { return false }
        backStack.removeLast()
        return true
    }

    /// Leave a pond, pointing the pack page underneath at the pond actually
    /// being left. Without this the "next level" chain and the debug skipper
    /// would still return to whichever pond the player first opened, which for a
    /// long chain can be a different page entirely.
    func leaveLevel(_ levelId: String) {
        let below = backStack.count - 2
        if below >= 0, case .packLevels(let packId, _) = backStack[below],
           !Levels.isBonus(levelId), Levels.indexOf(levelId) >= 0,
           Levels.packOf(levelId).id == packId {
            backStack[below] = .packLevels(packId: packId, focusLevelId: levelId)
        }
        back()
    }

    // MARK: - Level progression (identical rules to Android)

    /// First unsolved playable level, for the Splash (continue) button.
    func continueLevelId() -> String {
        let firstOpen = Levels.all.first { (stars[$0.id] ?? 0) == 0 && isUnlocked($0.id) }
        return (firstOpen ?? Levels.all[0]).id
    }

    /// Levels from `Catalog.premiumFromLevel` on are part of the premium upgrade.
    func isPremiumLevel(_ levelId: String) -> Bool {
        globalLevelNumber(levelId) >= Catalog.premiumFromLevel
    }

    /// How many levels the premium upgrade adds.
    func premiumLevelCount() -> Int { Levels.all.count - (Catalog.premiumFromLevel - 1) }

    /// A level is playable once every earlier level has at least one star -
    /// i.e. you clear the pond in order. There is no star-count gate. Premium
    /// owners skip even the ordering: every level is open outright, any order.
    func isUnlocked(_ levelId: String) -> Bool {
        // Testing only: "Unlock everything" opens the golden ponds too.
        if unlockAllFlag { return true }
        // Bonus ponds have their own gate: clear the run of ponds they close.
        if Levels.isBonus(levelId) {
            let pack = Levels.packOf(levelId)
            guard let bonus = pack.bonuses.first(where: { $0.level.id == levelId }) else { return false }
            return isBonusUnlocked(pack, bonus)
        }
        // The premium upgrade opens every pond outright - but not in a
        // closed-testing build, where premium is granted to everyone and that
        // would quietly throw the ordering away.
        if isPremium && !FreeMode.enabled { return true }
        if !isPremium && isPremiumLevel(levelId) { return false }
        let index = Levels.indexOf(levelId)
        guard let firstUnsolved = Levels.all.firstIndex(where: { (stars[$0.id] ?? 0) == 0 })
        else { return true }
        return index <= firstUnsolved
    }

    func globalLevelNumber(_ levelId: String) -> Int { Levels.indexOf(levelId) + 1 }

    /// The pack the player is working through right now.
    func currentPack() -> Pack { Levels.packOf(continueLevelId()) }

    /// A pack is open exactly when its first pond is.
    func isPackUnlocked(_ pack: Pack) -> Bool { isUnlocked(pack.levels[0].id) }

    /// Locked only because the premium upgrade isn't owned - a shop tap, not a wall.
    func isPackPremiumLocked(_ pack: Pack) -> Bool {
        !isPremium && isPremiumLevel(pack.levels[0].id)
    }

    /// Ponds cleared in this pack; its bonus pond is counted separately.
    func packSolved(_ pack: Pack) -> Int { pack.levels.count { (stars[$0.id] ?? 0) > 0 } }

    func packStars(_ pack: Pack) -> Int { pack.levels.reduce(0) { $0 + (stars[$1.id] ?? 0) } }

    /// A stage is open exactly when its first pond is.
    func isStageUnlocked(_ stage: PackStage) -> Bool { isUnlocked(stage.levels[0].id) }

    func stageSolved(_ stage: PackStage) -> Int { stage.levels.count { (stars[$0.id] ?? 0) > 0 } }

    func stageStars(_ stage: PackStage) -> Int { stage.levels.reduce(0) { $0 + (stars[$1.id] ?? 0) } }

    /// Which page of a pack to open on. See `stageIndexFor`.
    func currentStageIndex(_ pack: Pack, focusLevelId: String? = nil) -> Int {
        stageIndexFor(pack: pack, starMap: stars, focusLevelId: focusLevelId)
    }

    /// Ponds cleared overall, for the header on the packs screen.
    func solvedLevels() -> Int { Levels.all.count { (stars[$0.id] ?? 0) > 0 } }

    func isBonus(_ levelId: String) -> Bool { Levels.isBonus(levelId) }

    /// How many of the 30 bonus ponds have been cleared.
    func bonusPondsCleared() -> Int { Levels.bonusPonds.count { (stars[$0.id] ?? 0) > 0 } }

    /// A golden pond opens once every pond up to it in the pack has a star. It is
    /// never in the way: skipping it costs nothing but the reward.
    func isBonusUnlocked(_ pack: Pack, _ bonus: BonusPond) -> Bool {
        unlockAllFlag || pack.levels.prefix(bonus.opensAfter).allSatisfy { (stars[$0.id] ?? 0) > 0 }
    }

    /// The golden pond a player has just opened but not yet played, if any.
    func openBonus(_ pack: Pack) -> BonusPond? {
        pack.bonuses.first { (stars[$0.level.id] ?? 0) == 0 && isBonusUnlocked(pack, $0) }
    }

    /// The golden pond that clearing `levelId` has just opened, if any.
    func bonusOpenedBy(_ levelId: String, firstClear: Bool) -> BonusPond? {
        PondPulse.bonusOpenedBy(levelId: levelId, firstClear: firstClear, starMap: stars) {
            [self] pack, bonus, _ in isBonusUnlocked(pack, bonus)
        }
    }

    // MARK: - Ownership

    /// Whether a shop item is usable right now (free, earned, or bought).
    func isOwned(_ unlock: Unlock, productId: String) -> Bool {
        if Catalog.cosmeticsUnlocked { return true }
        let ownedIds = effectiveOwned
        if ownedIds.contains(FreeMode.unlockAllToken) { return true }
        switch unlock {
        case .free: return true
        case .bonusReward(let count): return bonusPondsCleared() >= count
        case .streakReward(let days): return dailyBestStreak >= days
        case .premium: return ownedIds.contains(Catalog.premiumId)
        // A theme friend is owned exactly when its theme is, whatever the theme
        // cost. Resolved one level deep and no further: no theme is itself
        // unlocked by a theme, so this cannot recurse.
        case .themeFriend(let themeId):
            guard let theme = Catalog.themes.first(where: { $0.id == themeId }) else { return false }
            return isOwned(theme.unlock, productId: Catalog.themeProductId(theme.id))
        // The five special friends: bought outright, restored by StoreKit.
        case .money: return ownedIds.contains(productId)
        // Bought, or won from the golden pond that also hands it out. Two doors
        // to the same item: the coin price is what it costs someone who does not
        // play the golden ponds, and clearing them is what it costs someone who
        // would rather not spend.
        case .coins(_, let bonusCount):
            if ownedIds.contains(productId) { return true }
            if let bonusCount { return bonusPondsCleared() >= bonusCount }
            return false
        }
    }

    /// Whether a decoration is the player's - bought, or paid out by a golden
    /// pond. The Decorate tray asks this instead of looking in the owned set on
    /// its own, which is all it used to do.
    func isDecorOwned(_ decor: PondCatalog.Decor) -> Bool {
        if Catalog.cosmeticsUnlocked { return true }
        let ownedIds = effectiveOwned
        if ownedIds.contains(FreeMode.unlockAllToken) { return true }
        if ownedIds.contains(PondCatalog.decorProductId(decor.id)) { return true }
        if let count = decor.bonusCount { return bonusPondsCleared() >= count }
        return false
    }

    /// Whether a sky is the player's. Day is free; the rest are coin purchases.
    func isWeatherOwned(_ weather: PondCatalog.Weather) -> Bool {
        if weather.price == 0 { return true }
        if Catalog.cosmeticsUnlocked { return true }
        let ownedIds = effectiveOwned
        return ownedIds.contains(FreeMode.unlockAllToken)
            || ownedIds.contains(PondCatalog.weatherProductId(weather.id))
    }

    /// Whether a water or a bank is the player's. The same question
    /// `isWeatherOwned` answers, asked of the other two shelves - Decorate used
    /// to look in the raw `owned` set itself, which is the one set that does not
    /// know what a tester or a golden pond has been handed.
    func isSurfaceOwned(_ surface: PondCatalog.Surface, productId: String) -> Bool {
        if surface.price == 0 { return true }
        if Catalog.cosmeticsUnlocked { return true }
        let ownedIds = effectiveOwned
        return ownedIds.contains(FreeMode.unlockAllToken) || ownedIds.contains(productId)
    }

    // MARK: - Coins

    /// The two halves of the star ledger, which pay at different rates.
    private static let campaignIds = Levels.all.map(\.id)
    private static let goldenIds = Levels.bonusPonds.map(\.id)

    /// Every coin progress has earned, recomputed rather than banked - see
    /// `CoinBank`. Nothing writes this; replaying a cleared pond recomputes to
    /// the same number, which is what makes coins unfarmable.
    var derivedCoins: Int {
        CoinBank.derived(
            campaignIds: Self.campaignIds,
            goldenIds: Self.goldenIds,
            starsOf: { stars[$0] ?? 0 },
            dailyClears: dailyTotal,
            bestStreak: dailyBestStreak,
            rushBests: rushBests.values,
            achievementCoins: Achievements.coins(achievements)
        )
    }

    /// Everything the badge shelf is allowed to look at, gathered in one place.
    ///
    /// Recomputed from progress like everything else, which is what lets the
    /// badges pay coins without a claimed set or a second ledger - see
    /// `Achievements`.
    var achievements: Achievements.Snapshot {
        Achievements.Snapshot(
            pondsCleared: solvedLevels(),
            stars: Levels.all.reduce(0) { $0 + (stars[$1.id] ?? 0) },
            goldenCleared: bonusPondsCleared(),
            dailyClears: dailyTotal,
            bestStreak: dailyBestStreak,
            bestRush: rushBests.values.max() ?? 0,
            gamesTotal: miniBests.values.reduce(0, +),
            friendsOwned: ownedSkinIds().count,
            decorOwned: PondCatalog.decor.count { isDecorOwned($0) }
        )
    }

    /// What the player can spend right now.
    ///
    /// "Unlock everything" adds `FreeMode.debugCoins` on top, and only here: the
    /// pile is *shown*, never banked, so switching the tester tools off puts the
    /// honest balance straight back. Nothing is debited while the switch is on
    /// either - see `ProgressStore.spending`.
    var coins: Int {
        CoinBank.balance(derived: derivedCoins, granted: coinsGranted, spent: coinsSpent)
            + (unlockAllFlag ? FreeMode.debugCoins : 0)
    }

    /// What the pond's games have paid out this week. Read as a pair so a stamp
    /// left over from last week reads as zero rather than as a spent ceiling.
    var pondEarnedThisWeek: Int {
        pondWeekStamp == CoinBank.weekOf(epochDay: today()) ? pondWeekTotal : 0
    }

    func canAfford(_ price: Int) -> Bool { FreeMode.affordable(coins: coins, price: price) }

    /// Buys a shop item with coins. Returns whether the coins were actually
    /// there - a refused purchase must not equip anything.
    @discardableResult
    func buyWithCoins(price: Int, productId: String) -> Bool {
        guard store.buyWithCoins(derived: derivedCoins, price: price, productId: productId)
        else { return false }
        owned = store.owned
        coinsSpent = store.coinsSpent
        return true
    }

    @discardableResult
    func buyHints(count: Int) -> Bool {
        guard store.buyHints(derived: derivedCoins, count: count) else { return false }
        hintsStored = store.hintsLeft
        coinsSpent = store.coinsSpent
        return true
    }

    @discardableResult
    func buyPondSlot() -> Bool {
        guard store.buyPondSlot(derived: derivedCoins) else { return false }
        pondSlots = store.pondSlots
        coinsSpent = store.coinsSpent
        return true
    }

    /// Buys room for one more saved pond.
    @discardableResult
    func buyLayoutSlot() -> Bool {
        guard store.buyLayoutSlot(derived: derivedCoins) else { return false }
        layoutSlots = store.layoutSlots
        coinsSpent = store.coinsSpent
        return true
    }

    // MARK: - The pond

    /// Friends owned before the pond is worth opening.
    ///
    /// The pond opens once three friends live there. One friend is a puddle and
    /// two is a pair; three is the first time the water looks inhabited, which is
    /// the only reason the screen exists.
    static let pondMinFriends = 3

    var pondUnlocked: Bool { ownedSkinIds().count >= Self.pondMinFriends }

    /// Every friend the player may put in the water, in catalog order.
    func ownedSkinIds() -> [String] {
        Catalog.skins
            .filter { isOwned($0.unlock, productId: Catalog.skinProductId($0.id)) }
            .map(\.id)
    }

    /// Who is actually swimming: the player's picks, minus anything they no
    /// longer own and anything past the seats they have.
    ///
    /// A pond nobody has ever arranged fills itself from the roster, because a
    /// pond that starts empty until you visit a picker is a pond whose first
    /// impression is an empty pond. A pond that *has* been arranged does not:
    /// topping it up used to refill a seat the moment it was emptied, so taking a
    /// friend out of a full pond instantly put a different one in, and the only
    /// way to change who was swimming looked like a random shuffle. An empty seat
    /// is now a seat you emptied.
    func pondCast() -> [String] {
        let roster = ownedSkinIds()
        let kept = Array(pondFriends.filter { roster.contains($0) }.prefix(pondSlots))
        return kept.isEmpty ? Array(roster.prefix(pondSlots)) : kept
    }

    func setPondFriends(_ ids: [String]) {
        store.setPondFriends(ids)
        pondFriends = ids
    }

    func setDecorSpot(id: String, at: CGPoint) {
        store.setDecorSpot(id: id, at: at)
        decorSpots[id] = at
    }

    func setDecorStored(id: String, stored: Bool) {
        store.setDecorStored(id: id, stored: stored)
        decorStored = store.decorStored
    }

    func setPondWeather(_ id: String) {
        store.setPondWeather(id)
        pondWeather = id
    }

    func setPondWater(_ id: String) {
        store.setPondWater(id)
        pondWater = id
    }

    func setPondShore(_ id: String) {
        store.setPondShore(id)
        pondShore = id
    }

    func savePondLayout(_ slot: Int, onPond: [String: CGPoint]) {
        store.savePondLayout(slot, onPond: onPond)
        pondLayouts = store.pondLayouts
    }

    func applyPondLayout(_ slot: Int) {
        guard store.applyPondLayout(slot) else { return }
        reloadPondState()
    }

    /// Puts a pond back that was never in a slot - how Undo reverses a switch.
    func restorePond(_ layout: PondLayout) {
        store.restorePondLayout(layout)
        reloadPondState()
    }

    func clearPondLayout(_ slot: Int) {
        store.clearPondLayout(slot)
        pondLayouts = store.pondLayouts
    }

    /// Puts a saved pond back into its slot - how Undo reverses a save or a clear.
    func putPondLayout(_ slot: Int, _ layout: PondLayout) {
        store.putPondLayout(slot, layout)
        pondLayouts = store.pondLayouts
    }

    /// Re-reads everything a saved pond can change, in one go.
    private func reloadPondState() {
        pondWeather = store.pondWeather
        pondWater = store.pondWater
        pondShore = store.pondShore
        pondFriends = store.pondFriends
        decorSpots = store.decorSpots
        decorStored = store.decorStored
        pondLayouts = store.pondLayouts
    }

    /// Banks a mini game run: the best score, and whatever the week's ceiling
    /// still allows the run to pay. Returns what was actually paid, so the
    /// results card can say "the week is done" rather than quietly showing a
    /// zero.
    @discardableResult
    func finishMiniGame(gameId: String, score: Int) -> Int {
        guard let game = PondCatalog.gameById(gameId) else { return 0 }
        store.recordMiniBest(gameId: gameId, score: score)
        miniBests = store.miniBests
        let paid = store.awardPondCoins(
            week: CoinBank.weekOf(epochDay: today()),
            want: PondCatalog.coinsFor(game, score: score)
        )
        pondWeekStamp = store.pondWeek
        pondWeekTotal = store.pondWeekEarned
        coinsGranted = store.coinsGranted
        let day = today()
        store.addQuest(day: day, .miniRuns)
        store.addQuest(day: day, .miniPoints, max(score, 0))
        store.noteQuestGame(day: day, gameId: gameId)
        settleQuests()
        return paid
    }

    // MARK: - Today's quests

    /// Today's three, drawn from the date.
    var questBoard: [Quests.Quest] { Quests.board(day: today()) }

    /// How many of today's three are finished. What the home screen's tile
    /// counts: the number that moves today, rather than the badge shelf's
    /// lifetime total, which moves a handful of times a month.
    var questsDoneToday: Int {
        let counters = questCounters
        return questBoard.reduce(0) { $0 + ($1.isDone(counters) ? 1 : 0) }
    }

    /// Whether every quest on today's board is finished - and so whether the
    /// bonus has been earned.
    var questBoardDone: Bool {
        let counters = questCounters
        return questBoard.allSatisfy { $0.isDone(counters) }
    }

    /// Re-reads today's counters and pays for anything that has just finished.
    ///
    /// Called after every counter that moves rather than at the moment of the
    /// win, so a quest that was completed by the same pond that completed
    /// another one still pays for both - and so the board is correct even if the
    /// app was killed between the doing and the looking.
    private func settleQuests() {
        let day = today()
        questCounters = store.questCounters(day: day)
        let board = Quests.board(day: day)
        for quest in board where quest.isDone(questCounters) {
            store.payQuest(day: day, id: quest.id, coins: quest.coins)
        }
        if board.allSatisfy({ $0.isDone(questCounters) }) {
            store.payQuest(day: day, id: Self.questBonusId, coins: Quests.allDoneBonus)
        }
        questPaid = store.questPaid(day: day)
        coinsGranted = store.coinsGranted
    }

    /// The id the all-three bonus is written down under. Not a quest kind, so it
    /// can never collide with one.
    static let questBonusId = "bonus"

    /// Adds to one of today's counters and settles the board.
    func noteQuest(_ counter: Quests.Counter, _ amount: Int = 1) {
        store.addQuest(day: today(), counter, amount)
        settleQuests()
    }

    /// Raises a best-of counter and settles the board.
    func noteQuestBest(_ counter: Quests.Counter, _ value: Int) {
        store.raiseQuest(day: today(), counter, to: value)
        settleQuests()
    }

    // MARK: - The daily pond

    /// Today, as the app reckons days: the device's local calendar date.
    func today() -> Int { currentEpochDay() }

    /// The streak as it actually stands today.
    var dailyStreak: Int {
        liveDailyStreak(lastDay: dailyLastDay, epochDay: today(), storedStreak: dailyStreakStored)
    }

    /// Whether today's pond has already been cleared.
    var dailyDoneToday: Bool { dailyLastDay == today() }

    /// Today's pond. Everybody with the same date gets the same one, and it is
    /// drawn from the free 300 so the daily is never a locked door - a premium
    /// upgrade buys more levels, not a different daily.
    func dailySpec(_ epochDay: Int? = nil) -> LevelSpec {
        let day = epochDay ?? today()
        let pool = Array(Levels.all.prefix(Catalog.premiumFromLevel - 1))
        return pool[dailyPondIndex(epochDay: day, poolSize: pool.count)]
    }

    /// Banks a Daily Pond clear. Returns the payout only when the day actually
    /// paid out, so replaying today's pond stays quiet.
    @discardableResult
    func recordDailyWin(_ epochDay: Int? = nil) -> ProgressStore.DailyPayout? {
        let payout = store.recordDailyWin(epochDay: epochDay ?? today())
        guard payout != nil else { return nil }
        dailyLastDay = store.dailyLastDay
        dailyStreakStored = store.dailyStreak
        dailyBestStreak = store.dailyBestStreak
        dailyTotal = store.dailyTotal
        hintsStored = store.hintsLeft
        claimFirstClearOfDay()
        noteQuest(.daily)
        return payout
    }

    // MARK: - Wins

    /// Whether today's first pond has already paid its bonus.
    var firstClearClaimedToday: Bool { firstClearDay == today() }

    /// Pays the day's first clear, whichever kind of pond it was.
    ///
    /// One call site per kind of win rather than one inside `recordResult`,
    /// because a golden pond and a daily bank their stars through paths of their
    /// own - and a bonus that only some ponds could pay would be a bonus the
    /// player could not predict.
    private func claimFirstClearOfDay() {
        guard store.claimFirstClear(day: today()) > 0 else { return }
        firstClearDay = store.firstClearDay
        coinsGranted = store.coinsGranted
    }

    func recordWin(levelId: String, stars starCount: Int, splashes: Int = 0) {
        let before = stars[levelId] ?? 0
        store.recordResult(levelId: levelId, stars: starCount)
        stars[levelId] = max(before, starCount)
        // Quests count the play, not the progress: a pond re-cleared for the
        // fourth time still counts towards "clear five ponds today", because the
        // quest is asking what you did this morning rather than what you own.
        let day = today()
        store.addQuest(day: day, .ponds)
        store.addQuest(day: day, .stars, max(starCount, 0))
        if starCount >= 3 { store.addQuest(day: day, .three) }
        store.addQuest(day: day, .splashes, max(splashes, 0))
        if starCount > 0 { claimFirstClearOfDay() }
        settleQuests()
    }

    /// The golden pond whose clear just paid out its prize, if any. The win card
    /// reads it to decide between "here is your prize" and "lovely splashing";
    /// a replay clears it, so the payout is only ever announced once.
    @Published private(set) var bonusPrizePaidFor: String?

    /// Banks a bonus pond clear. Only the pond's first ever clear pays a prize.
    @discardableResult
    func recordBonusWin(levelId: String, stars starCount: Int) -> Bool {
        let granted = store.recordBonusResult(levelId: levelId, stars: starCount)
        stars[levelId] = max(stars[levelId] ?? 0, starCount)
        if granted { bonusPrizePaidFor = levelId }
        if starCount > 0 {
            claimFirstClearOfDay()
            noteQuest(.golden)
        }
        return granted
    }

    /// Called when a pond is restarted: a replay has to earn its own verdict.
    func clearBonusPayoutNotice() { bonusPrizePaidFor = nil }

    // MARK: - Splash Rush

    /// The level run for one Splash Rush game: a handful of random ponds from
    /// each pack, easy to hard, premium packs only when owned. The play screen
    /// wraps the index if a marathon outruns the list.
    func rushSequence() -> [LevelSpec] {
        let playablePacks = Levels.packs
            .filter { isPremium || !isPremiumLevel($0.levels[0].id) }
            .sorted { $0.difficulty < $1.difficulty }
        return playablePacks.flatMap { $0.levels.shuffled().prefix(Self.rushPerPack) } +
            playablePacks.last!.levels.shuffled()
    }

    /// Kept the rush run about sixty ponds long when packs were re-cut.
    private static let rushPerPack = 7

    func recordRushScore(durationSec: Int, score: Int) {
        store.recordRushBest(durationSec: durationSec, score: score)
        rushBests[durationSec] = max(rushBests[durationSec] ?? 0, score)
        let day = today()
        store.addQuest(day: day, .rushRuns)
        store.raiseQuest(day: day, .rushBest, to: score)
        settleQuests()
    }

    // MARK: - Settings & cosmetics

    func setHaptics(_ value: Bool) {
        store.setHaptics(value)
        haptics = value
    }

    func setLanguage(_ language: Language?) {
        store.setLanguage(language)
        languageOverride = language
    }

    func setDebugTools(_ value: Bool) {
        store.setDebugTools(value)
        debugTools = value
    }

    /// Testing only: opens every pond, hands over every unlockable, tops up
    /// coins and hints, and stops anything being charged. See `FreeMode`.
    func setUnlockAll(_ value: Bool) {
        store.setUnlockAll(value)
        unlockAllFlag = store.unlockAll
    }

    /// Testing only: 500 coins, banked for real.
    ///
    /// Granted rather than shown, which is the whole difference between these
    /// three buttons and the switch above them. "Unlock everything" hands the
    /// goods over *and* stops anything being charged, so every price on every
    /// shelf becomes decoration - which is exactly no use when the thing you
    /// wanted to look at was the prices. These spend and debit like anybody
    /// else's coins.
    func testGrantCoins(_ amount: Int = 500) {
        store.grantCoins(amount)
        coinsGranted = store.coinsGranted
    }

    /// Testing only: every friend on the shelf, and nothing else.
    ///
    /// Friends alone because they are what the pond is made of - three of them
    /// is the gate on My Pond and the roster is the screen worth looking at
    /// full. Pads, themes, decorations and seats keep their prices and stay
    /// locked, so the shop still reads honestly next door.
    func testGrantFriends() {
        store.grantProducts(Catalog.skins.map { Catalog.skinProductId($0.id) })
        owned = store.owned
    }

    /// Testing only: two more seats in the pond, free.
    func testGrantPondSlots(_ count: Int = 2) {
        store.grantPondSlots(count)
        pondSlots = store.pondSlots
        layoutSlots = store.layoutSlots
    }

    /// The pond `delta` steps along the play order from `levelId`, or nil at
    /// either end. Ignores locks and premium on purpose: it exists only behind
    /// `debugTools`, to walk the ramp without replaying it.
    func debugNeighbour(_ levelId: String, delta: Int) -> LevelSpec? {
        let at = Levels.indexOf(levelId)
        guard at >= 0 else { return nil }
        let to = at + delta
        return Levels.all.indices.contains(to) ? Levels.all[to] : nil
    }

    func selectTheme(_ id: String) {
        store.setSelectedTheme(id)
        themeId = id
    }

    func selectSkin(_ id: String) {
        store.setSelectedSkin(id)
        skinId = id
    }

    func selectPad(_ id: String) {
        store.setSelectedPad(id)
        padId = id
    }

    // MARK: - Hints

    /// Spends one hint the first time a level is hinted; the level is then
    /// remembered locally, so re-showing its glow later - after a restart, an
    /// undo or a replay - never solves again from scratch and never costs a
    /// second hint.
    func useHint(levelId: String) {
        // Closed testing, or a tester with everything unlocked: hints cost
        // nothing, so the counter is left alone. The level is still remembered,
        // so its glow stays free on a replay.
        let free = FreeMode.enabled || unlockAllFlag
        if !free && !hintedLevels.contains(levelId) {
            store.setHintsLeft(hintsStored - 1)
            hintsStored = store.hintsLeft
        }
        hintedLevels.insert(levelId)
        store.setHintedLevels(hintedLevels)
    }

    // MARK: - Purchases

    /// The price to show for a product: the App Store's localized price once
    /// loaded, Catalog's display price until then.
    func price(_ productId: String, fallback: String) -> String {
        prices[productId] ?? fallback
    }

    /// StoreKit's own formatted price, or nil when the store has not quoted one.
    ///
    /// Nil is the signal that a product must not be offered: either the store is
    /// unreachable or the product is not configured in App Store Connect, and
    /// both mean the same thing to a player. It is the only thing standing
    /// between an unreachable store and giving a paid friend away.
    func price(_ productId: String, fallback: String?) -> String? {
        prices[productId] ?? fallback
    }

    /// Runs the App Store payment sheet and returns true once the verified
    /// purchase has been granted, so the caller can equip the item. The hint
    /// pack and the coin packs are consumables: they credit hints or coins
    /// instead of unlocking a product id.
    func purchase(_ productId: String) async -> Bool {
        guard !purchasing else { return false }
        purchasing = true
        defer { purchasing = false }
        return await storeManager.purchase(productId)
    }

    /// App Store restore, for non-consumables on a new device.
    func restorePurchases() async {
        guard !purchasing else { return }
        purchasing = true
        defer { purchasing = false }
        await storeManager.restore()
    }

    /// Records a verified non-consumable. Purchases survive progress resets.
    private func grant(_ productId: String) {
        guard !owned.contains(productId) else { return }
        owned.insert(productId)
        store.setOwned(owned)
    }

    /// A refunded purchase is taken back; equipped cosmetics fall back to defaults.
    private func revoke(_ productId: String) {
        guard owned.contains(productId) else { return }
        owned.remove(productId)
        store.setOwned(owned)
        if Catalog.themeProductId(themeId) == productId { selectTheme("dusk") }
        if Catalog.skinProductId(skinId) == productId { selectSkin("duck") }
        if Catalog.padProductId(padId) == productId { selectPad("lily") }
    }

    private func creditHints(_ count: Int) {
        store.setHintsLeft(hintsStored + count)
        hintsStored = store.hintsLeft
    }

    /// A verified coin pack. Banked as *bought* rather than earned, so a reset
    /// hands it straight back - see `ProgressStore.resetProgress`.
    private func creditCoins(_ amount: Int) {
        store.grantPurchasedCoins(amount)
        coinsGranted = store.coinsGranted
    }

    func resetProgress() {
        store.resetProgress()
        stars = store.stars
        rushBests = store.rushBests
        hintedLevels = store.hintedLevels
        hintsStored = store.hintsLeft
        owned = store.owned
        themeId = store.selectedTheme
        skinId = store.selectedSkin
        padId = store.selectedPad
        coinsSpent = store.coinsSpent
        coinsGranted = store.coinsGranted
        firstClearDay = store.firstClearDay
        miniBests = store.miniBests
        pondWeather = store.pondWeather
        pondWater = store.pondWater
        pondShore = store.pondShore
        pondLayouts = store.pondLayouts
        pondSlots = store.pondSlots
        layoutSlots = store.layoutSlots
        pondFriends = store.pondFriends
        decorSpots = store.decorSpots
        decorStored = store.decorStored
        pondWeekStamp = store.pondWeek
        pondWeekTotal = store.pondWeekEarned
        dailyLastDay = store.dailyLastDay
        dailyStreakStored = store.dailyStreak
        dailyBestStreak = store.dailyBestStreak
        dailyTotal = store.dailyTotal
        // The quest board was wiped with everything else; the screens holding
        // the old counters have to be told, or a reset leaves half-filled bars
        // over a save with nothing behind them.
        questCounters = store.questCounters(day: currentEpochDay())
        questPaid = store.questPaid(day: currentEpochDay())
        bonusPrizePaidFor = nil
        goHome()
    }

    /// Every product id the two catalogues between them sell. Only ever used by
    /// `effectiveOwned` while "Unlock everything" is on.
    private static let everyProductId: Set<String> = {
        var out: Set<String> = [Catalog.premiumId]
        Catalog.themes.forEach { out.insert(Catalog.themeProductId($0.id)) }
        Catalog.skins.forEach { out.insert(Catalog.skinProductId($0.id)) }
        Catalog.pads.forEach { out.insert(Catalog.padProductId($0.id)) }
        PondCatalog.decor.forEach { out.insert(PondCatalog.decorProductId($0.id)) }
        PondCatalog.weathers.forEach { out.insert(PondCatalog.weatherProductId($0.id)) }
        // The water and the bank are bought like a sky and were missing here,
        // so "Unlock everything" opened every sky and no shoreline.
        PondCatalog.waters.forEach { out.insert(PondCatalog.waterProductId($0.id)) }
        PondCatalog.shores.forEach { out.insert(PondCatalog.shoreProductId($0.id)) }
        return out
    }()
}

// MARK: - Free functions
//
// Android keeps these outside the view model so its tests can hold them to
// account without an Android runtime. Same reason here: no SwiftUI, no state.

/// Which pond in the pool is `epochDay`'s daily.
///
/// Not a plain hash of the date. A hash into 300 ponds serves the *same* pond
/// two days running about once a year - rare enough to miss in testing, and
/// exactly the kind of thing a player on a streak notices and reads as broken.
///
/// So the pool is walked instead of sampled. Days are cut into blocks of
/// `poolSize`, each block gets its own starting point and its own stride chosen
/// coprime to the pool, and stepping by that stride visits every pond exactly
/// once before any repeats - a full year of dailies with no pond twice. The one
/// place two days could still collide is a block boundary, and the nudge below
/// moves that day on by one.
///
/// Everything is fixed integer arithmetic rather than a seeded RNG, so the pond
/// for a given date can never drift with a toolchain change.
func dailyPondIndex(epochDay: Int, poolSize: Int) -> Int {
    precondition(poolSize > 0, "empty daily pool")
    if poolSize < 3 { return rawDailyIndex(epochDay: epochDay, poolSize: poolSize) }
    let raw = rawDailyIndex(epochDay: epochDay, poolSize: poolSize)
    // Only ever true on a block boundary, and yesterday is never itself a
    // boundary when the pool is 3 or more, so one step is always enough.
    return raw == rawDailyIndex(epochDay: epochDay - 1, poolSize: poolSize)
        ? (raw + 1) % poolSize
        : raw
}

/// The block walk, before the boundary nudge.
private func rawDailyIndex(epochDay: Int, poolSize: Int) -> Int {
    // Pools this small have no room to choose a stride: one pond is always
    // itself, and two ponds can only alternate. Both are guards for a future
    // pool that shrinks, never for the shipped 300.
    if poolSize == 1 { return 0 }
    if poolSize == 2 { return ((epochDay % 2) + 2) % 2 }
    let n = poolSize
    let block = Int((Double(epochDay) / Double(n)).rounded(.down))
    let step = ((epochDay % n) + n) % n
    let h = mix64(UInt64(bitPattern: Int64(block)))
    let start = Int((h >> 20) % UInt64(n))
    return (start + step * strideFor(n: n, seed: h)) % n
}

/// A stride that is coprime to `n`, so stepping by it cycles through every one
/// of the `n` ponds before returning to where it began.
///
/// Drawn from 2..n-1, never 1. A stride of 1 walks the pool in order, and then
/// the boundary nudge - which moves a day on by one - lands exactly on the pond
/// the next day was already going to use, reintroducing the repeat the whole
/// scheme exists to prevent. n-1 is always coprime to n, so a candidate always
/// exists.
private func strideFor(n: Int, seed: UInt64) -> Int {
    var s = 2 + Int((seed >> 1) % UInt64(n - 2))
    while gcd(s, n) != 1 { s = s + 1 >= n ? 2 : s + 1 }
    return s
}

private func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }

/// SplitMix64's finalizer: cheap, fixed, and well spread in the low bits.
private func mix64(_ value: UInt64) -> UInt64 {
    var z = value &* 0x9E37_79B9_7F4A_7C15 &+ 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
    z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
    return z ^ (z >> 31)
}

/// Which page of a pack to open on.
///
/// If the player came here from a pond - backing out of it, or "all levels" - it
/// is that pond's page. Falling through to the progress frontier instead is what
/// made backing out of level 5 land on the page holding level 35: right for a
/// cold open from the pack gallery, wrong for someone who was just looking at
/// level 5.
///
/// Otherwise: the first stage still holding an unsolved pond, or the last once
/// the pack is cleared.
func stageIndexFor(pack: Pack, starMap: [String: Int], focusLevelId: String? = nil) -> Int {
    if let focusLevelId {
        if let at = pack.stages.firstIndex(where: { stage in
            stage.levels.contains { $0.id == focusLevelId } || stage.bonus.level.id == focusLevelId
        }) { return at }
    }
    return pack.stages.firstIndex { stage in
        stage.levels.contains { (starMap[$0.id] ?? 0) == 0 }
    } ?? pack.stages.count - 1
}

/// The golden pond that clearing `levelId` has just opened, if any.
///
/// Two conditions, and both matter:
///
///  - `levelId` is the pond the golden one is *gated on* - the last of the run
///    that opens it, the fifteenth or thirtieth or forty-fifth. Offering instead
///    the first unplayed golden pond anywhere in the pack is what made a skipped
///    one follow the player around: walk past the one at level 15, and every win
///    from 16 onwards went on asking about it, including wins in a later stage.
///  - this clear was the pond's `firstClear`. Replaying level 15 later is not a
///    fresh invitation.
///
/// A golden pond that is never offered is not lost: it keeps its row in the
/// level list, where it can be started any time.
func bonusOpenedBy(
    levelId: String,
    firstClear: Bool,
    starMap: [String: Int],
    unlocked: (Pack, BonusPond, [String: Int]) -> Bool
) -> BonusPond? {
    guard firstClear, !Levels.isBonus(levelId), Levels.indexOf(levelId) >= 0 else { return nil }
    let pack = Levels.packOf(levelId)
    guard let bonus = pack.bonuses.first(where: { bonus in
        bonus.opensAfter >= 1 && bonus.opensAfter <= pack.levels.count
            && pack.levels[bonus.opensAfter - 1].id == levelId
    }) else { return nil }
    guard (starMap[bonus.level.id] ?? 0) == 0 else { return nil }
    return unlocked(pack, bonus, starMap) ? bonus : nil
}
