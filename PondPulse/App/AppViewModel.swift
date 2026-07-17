//
//  AppViewModel.swift
//  PondPulse
//
//  App-wide state and navigation, ported from the Android ui/AppViewModel.kt.
//  Android's StateFlows become @Published values that write through the
//  UserDefaults-backed ProgressStore.
//

import Combine
import SwiftUI

enum Screen: Equatable {
    case home
    case packs
    case game(levelId: String)
    case settings
    case shop
    case rush
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
    @Published private(set) var hintsLeft: Int
    @Published private(set) var hintedLevels: Set<String>
    /// In-app language override; nil follows the device language.
    @Published private(set) var languageOverride: Language?

    /// App Store localized prices by product id; Catalog's display prices are
    /// the fallback until the store answers (or when it can't).
    @Published private(set) var prices: [String: String] = [:]
    /// True while a payment sheet is up, so the shop blocks double-taps.
    @Published private(set) var purchasing = false

    @Published var backStack: [Screen] = [.home]

    init() {
        haptics = store.haptics
        stars = store.stars
        rushBests = store.rushBests
        owned = store.owned
        themeId = store.selectedTheme
        skinId = store.selectedSkin
        padId = store.selectedPad
        hintsLeft = store.hintsLeft
        hintedLevels = store.hintedLevels
        languageOverride = store.language
        applyDebugLaunchOverrides()

        // Verified App Store outcomes flow back into the persisted state.
        storeManager.onEntitled = { [weak self] productId in self?.grant(productId) }
        storeManager.onRevoked = { [weak self] productId in self?.revoke(productId) }
        storeManager.onHintsPurchased = { [weak self] count in self?.creditHints(count) }
        Task { [weak self] in
            await self?.storeManager.load()
            self?.prices = self?.storeManager.displayPrices ?? [:]
        }
    }

    /// DEBUG-only: jump straight into a level (`PP_START_LEVEL=<n>`) or a
    /// screen (`PP_START_SCREEN=packs|shop|rush|settings`), passed via
    /// `SIMCTL_CHILD_*` - mirrors linequest's LQ_START_LEVEL. Never affects
    /// normal launches.
    private func applyDebugLaunchOverrides() {
        #if DEBUG
        let env = ProcessInfo.processInfo.environment
        // `PP_PREMIUM=1` grants premium in memory only (never persisted), so
        // premium flows can be inspected without a StoreKit configuration.
        if env["PP_PREMIUM"] != nil {
            owned.insert(Catalog.premiumId)
        }
        if let raw = env["PP_START_LEVEL"], let n = Int(raw), (1...Levels.all.count).contains(n) {
            backStack = [.home, .game(levelId: Levels.all[n - 1].id)]
        } else if let screen = env["PP_START_SCREEN"] {
            switch screen {
            case "packs": backStack = [.home, .packs]
            case "shop": backStack = [.home, .shop]
            case "rush": backStack = [.home, .rush]
            case "settings": backStack = [.home, .settings]
            default: break
            }
        }
        #endif
    }

    var totalStars: Int { stars.values.reduce(0, +) }

    var isPremium: Bool { owned.contains(Catalog.premiumId) }

    var palette: PondPalette { Catalog.themeById(themeId).palette }

    var language: Language { languageOverride ?? .deviceDefault() }

    var strings: Strings { Strings(language: language) }

    // MARK: - Navigation

    var current: Screen { backStack.last ?? .home }

    func navigate(_ screen: Screen) {
        backStack.append(screen)
    }

    func replaceTop(_ screen: Screen) {
        backStack[backStack.count - 1] = screen
    }

    @discardableResult
    func back() -> Bool {
        guard backStack.count > 1 else { return false }
        backStack.removeLast()
        return true
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
        if isPremium { return true }
        if isPremiumLevel(levelId) { return false }
        let index = Levels.indexOf(levelId)
        let firstUnsolved = Levels.all.firstIndex { (stars[$0.id] ?? 0) == 0 }
        return firstUnsolved == nil || index <= firstUnsolved!
    }

    func globalLevelNumber(_ levelId: String) -> Int { Levels.indexOf(levelId) + 1 }

    /// Highest global level number solved so far (0 = none).
    func highestSolvedLevel() -> Int {
        (Levels.all.lastIndex { (stars[$0.id] ?? 0) > 0 } ?? -1) + 1
    }

    /// Whether a shop item is usable right now (free, earned, or bought).
    func isOwned(_ unlock: Unlock, productId: String) -> Bool {
        switch unlock {
        case .free: true
        case .levelReward(let level): highestSolvedLevel() >= level
        case .premium: isPremium
        case .paid: owned.contains(productId)
        }
    }

    func recordWin(levelId: String, stars starCount: Int) {
        store.recordResult(levelId: levelId, stars: starCount)
        stars[levelId] = max(stars[levelId] ?? 0, starCount)
    }

    // MARK: - Splash Rush

    /// The level run for one Splash Rush game: a couple of random ponds from
    /// each pack, easy to hard, premium packs only when owned. The play screen
    /// wraps the index if a marathon outruns the list.
    func rushSequence() -> [LevelSpec] {
        let playablePacks = Levels.packs
            .filter { isPremium || !isPremiumLevel($0.levels[0].id) }
            .sorted { $0.difficulty < $1.difficulty }
        return playablePacks.flatMap { $0.levels.shuffled().prefix(2) } +
            playablePacks.last!.levels.shuffled()
    }

    func recordRushScore(durationSec: Int, score: Int) {
        store.recordRushBest(durationSec: durationSec, score: score)
        rushBests[durationSec] = max(rushBests[durationSec] ?? 0, score)
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
        if !hintedLevels.contains(levelId) {
            store.setHintsLeft(hintsLeft - 1)
            hintsLeft = store.hintsLeft
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

    /// Runs the App Store payment sheet and returns true once the verified
    /// purchase has been granted, so the caller can equip the item.
    /// The hint pack is a consumable: it credits hints instead of unlocking.
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
        store.setHintsLeft(hintsLeft + count)
        hintsLeft = store.hintsLeft
    }

    func resetProgress() {
        store.resetProgress()
        stars = store.stars
        rushBests = store.rushBests
        hintedLevels = store.hintedLevels
    }
}
