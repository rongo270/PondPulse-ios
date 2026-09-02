//
//  ProgressStore.swift
//  PondPulse
//
//  UserDefaults-backed persistence, mirroring the Android ProgressRepository
//  key for key ("stars_1-4", "rush_best_60", "owned_products", "coins_spent",
//  "pond_friends", ...) so the two platforms stay comparable. Pure storage -
//  AppViewModel owns the published state and writes through here.
//
//  Android reaches every one of these writes through a DataStore `edit` block,
//  which is what makes a read-check-write atomic over there. UserDefaults has no
//  such block, so the equivalent guarantee here is that every caller is on
//  `AppViewModel`, which is `@MainActor`: the read, the affordability check and
//  the write all run in one hop of the main actor and nothing can interleave
//  between them. Keep it that way - a coin spend that debited without delivering
//  has no repair path.
//

import CoreGraphics
import Foundation

// MARK: - Daily streak arithmetic
//
// Free of storage on purpose, exactly as on Android, so the rules can be read
// (and tested) without a store in hand.

/// The streak after clearing the daily on `epochDay`, given the last day cleared
/// and the streak standing before it.
///
/// Clearing yesterday's pond continues the run; any longer gap starts a new one
/// at 1, never at 0 - the clear being counted is itself day one.
func nextDailyStreak(lastDay: Int, epochDay: Int, storedStreak: Int) -> Int {
    lastDay == epochDay - 1 ? storedStreak + 1 : 1
}

/// The streak as it actually stands on `epochDay`.
///
/// The stored counter is only half the answer: a stored 9 whose last clear was a
/// week ago is a dead run, and showing it would promise a streak bonus the next
/// clear will not pay. Cleared today or yesterday, the run is still alive.
func liveDailyStreak(lastDay: Int, epochDay: Int, storedStreak: Int) -> Int {
    (lastDay == epochDay || lastDay == epochDay - 1) ? storedStreak : 0
}

/// Hints one daily clear pays: a flat two, plus one per full week of streak, up
/// to `ProgressStore.dailyStreakBonusCap` extra.
func dailyHintPayout(streak: Int) -> Int {
    ProgressStore.dailyHintReward + min(streak / 7, ProgressStore.dailyStreakBonusCap)
}

/// Today, as days since the epoch in the phone's own calendar.
///
/// Local, not UTC: "today's pond" has to mean the day the player is living in,
/// or the daily rolls over in the middle of their evening.
func currentEpochDay(_ date: Date = Date()) -> Int {
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: date)
    let epoch = calendar.startOfDay(for: Date(timeIntervalSince1970: 0))
    return calendar.dateComponents([.day], from: epoch, to: start).day ?? 0
}

struct ProgressStore {

    /// Hints every install starts with; buying packs adds more.
    static let freeHints = 150

    /// Hints for clearing a Daily Pond, before the streak bonus.
    static let dailyHintReward = 2

    /// One extra hint per full week of streak, capped. The cap matters: an
    /// uncapped payout would eventually hand out more hints than a player could
    /// spend, and the hint economy is what the shop's hint pack sells against.
    static let dailyStreakBonusCap = 3

    /// Streak lengths that pay out an exclusive cosmetic.
    static let streakMilestones = [7, 30, 100]

    /// What one Daily Pond clear paid out.
    struct DailyPayout {
        let hints: Int
        let streak: Int
        let isNewBestStreak: Bool
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let haptics = "haptics"
        static let owned = "owned_products"
        static let theme = "selected_theme"
        static let skin = "selected_skin"
        static let pad = "selected_pad"
        static let hintsLeft = "hints_left"
        static let hintedLevels = "hinted_levels"
        static let language = "app_language"

        /// Developer tools: a level skipper in the pond and a few unlocks.
        /// Persisted so it survives a restart mid-session, but the switch that
        /// sets it only exists in debug builds, so a shipped app can never turn
        /// it on.
        static let debugTools = "debug_tools"

        /// Testing: "Unlock everything". Only reachable while `FreeMode.enabled`,
        /// which is false on iOS - so this reads as false whatever it holds.
        static let unlockAll = "test_unlock_all"

        /// Golden ponds that have already paid out their prize. Kept apart from
        /// the stars so the win card fires exactly once per pond.
        static let bonusPaid = "bonus_paid"

        /// The Daily Pond ledger. `dailyLastDay` is the epoch day of the last
        /// cleared daily, which is what makes "already done today" and "streak
        /// still alive" answerable without a second timestamp.
        ///
        /// `dailyBestStreak` - not the live streak - is what the streak
        /// cosmetics are gated on, because a shop unlock is permanent: missing a
        /// Tuesday must cost you the run, never a friend you already earned.
        static let dailyLastDay = "daily_last_day"
        static let dailyStreak = "daily_streak"
        static let dailyBestStreak = "daily_best_streak"
        static let dailyTotal = "daily_total"

        /// The coin ledger's two writable halves. The third - what progress has
        /// earned - is not stored at all: `CoinBank.derived` recomputes it from
        /// stars, dailies, streak and rush bests every time, which is what makes
        /// coins impossible to farm by replaying a pond.
        static let coinsGranted = "coins_granted"
        static let coinsSpent = "coins_spent"

        /// The mini games' weekly ceiling, as a week stamp and a running total
        /// inside it. Stored together so rolling over to a new week is one
        /// comparison rather than a scheduled job: any write that finds a stale
        /// stamp resets the total before adding to it.
        static let pondWeek = "pond_week"
        static let pondWeekEarned = "pond_week_earned"

        /// The pond's own settings. Decorations and skies live in `owned`.
        static let pondWeather = "pond_weather"
        static let pondFriends = "pond_friends"
        static let pondSlots = "pond_slots"

        /// Where each decoration has been dragged to, as `id:x,y;id:x,y`.
        ///
        /// One string rather than a key per item because the whole map is read
        /// and written together and a decoration is never worth a key of its
        /// own. Anything missing falls back to the catalogue's anchor, so a pond
        /// arranged before an item existed still opens.
        static let decorSpots = "decor_spots"

        /// Owned decorations the player has taken back out of the pond.
        static let decorStored = "decor_stored"

        /// The surface of the water and the bank around it, kept apart from the
        /// sky. Bought like a sky and stored like one; the first of each is free
        /// and is what an unarranged pond looks like.
        static let pondWater = "pond_water"
        static let pondShore = "pond_shore"

        /// The three saved ponds, one `PondLayout` string each.
        static func layout(_ slot: Int) -> String { "pond_layout_\(slot)" }

        static func stars(_ levelId: String) -> String { "stars_\(levelId)" }
        static func rushBest(_ durationSec: Int) -> String { "rush_best_\(durationSec)" }
        static func miniBest(_ gameId: String) -> String { "mini_best_\(gameId)" }
    }

    /// Splash Rush durations offered, in seconds.
    static let rushDurations = [60, 180, 300]

    // MARK: - Reads

    var haptics: Bool { defaults.object(forKey: Keys.haptics) as? Bool ?? true }

    var debugTools: Bool { defaults.bool(forKey: Keys.debugTools) }

    /// Whether the tester has asked for everything to be open. Always false
    /// unless `FreeMode.enabled`: the switch that sets it is not built into a
    /// live build, and this ignores anything an old preference left behind.
    var unlockAll: Bool { FreeMode.enabled && defaults.bool(forKey: Keys.unlockAll) }

    /// levelId -> stars (0 = unsolved), golden ponds included.
    var stars: [String: Int] {
        Dictionary(uniqueKeysWithValues: (Levels.all + Levels.bonusPonds).map {
            ($0.id, defaults.integer(forKey: Keys.stars($0.id)))
        })
    }

    /// Product ids bought so far ("premium", "theme_sakura", "skin_koi", ...).
    var owned: Set<String> { Set(defaults.stringArray(forKey: Keys.owned) ?? []) }

    /// Splash Rush: durationSec -> best score (missing = never played).
    var rushBests: [Int: Int] {
        var bests: [Int: Int] = [:]
        for sec in Self.rushDurations where defaults.object(forKey: Keys.rushBest(sec)) != nil {
            bests[sec] = defaults.integer(forKey: Keys.rushBest(sec))
        }
        return bests
    }

    /// gameId -> best score ever, for the four pond games.
    var miniBests: [String: Int] {
        Dictionary(uniqueKeysWithValues: PondCatalog.games.map {
            ($0.id, defaults.integer(forKey: Keys.miniBest($0.id)))
        })
    }

    /// Epoch day of the last Daily Pond cleared, or -1 if none ever was.
    var dailyLastDay: Int { defaults.object(forKey: Keys.dailyLastDay) as? Int ?? -1 }

    /// Longest run of consecutive daily clears; what the streak prizes read.
    var dailyBestStreak: Int { defaults.integer(forKey: Keys.dailyBestStreak) }

    /// The live streak as stored. It is only meaningful next to `dailyLastDay` -
    /// read the two together through `liveDailyStreak`.
    var dailyStreak: Int { defaults.integer(forKey: Keys.dailyStreak) }

    var dailyTotal: Int { defaults.integer(forKey: Keys.dailyTotal) }

    var selectedTheme: String { defaults.string(forKey: Keys.theme) ?? "dusk" }
    var selectedSkin: String { defaults.string(forKey: Keys.skin) ?? "duck" }
    var selectedPad: String { defaults.string(forKey: Keys.pad) ?? "lily" }

    /// Coins bought or paid out by the pond, as a lifetime total.
    var coinsGranted: Int { defaults.integer(forKey: Keys.coinsGranted) }

    /// Coins spent, as a lifetime total.
    var coinsSpent: Int { defaults.integer(forKey: Keys.coinsSpent) }

    /// The mini games' week stamp and what it has paid so far. Read the two
    /// together: a stamp older than this week means the total is spent history,
    /// not this week's tally.
    var pondWeek: Int { defaults.object(forKey: Keys.pondWeek) as? Int ?? -1 }
    var pondWeekEarned: Int { defaults.integer(forKey: Keys.pondWeekEarned) }

    var pondWeather: String { defaults.string(forKey: Keys.pondWeather) ?? "day" }

    /// Extra seats bought; the pond always holds `CoinBank.baseSlots` besides.
    var pondSlots: Int { CoinBank.baseSlots + defaults.integer(forKey: Keys.pondSlots) }

    /// Which friends are in the water, in the order they were picked.
    ///
    /// Stored as one comma-joined string rather than an array: the pond shows
    /// them in the order you chose, and this is the same encoding Android
    /// writes. Empty means "never chosen", which the pond reads as "fill it with
    /// whatever I own".
    var pondFriends: [String] {
        (defaults.string(forKey: Keys.pondFriends) ?? "")
            .split(separator: ",", omittingEmptySubsequences: true)
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    /// id -> where it was dragged to, in pond fractions.
    var decorSpots: [String: CGPoint] {
        var spots: [String: CGPoint] = [:]
        for entry in (defaults.string(forKey: Keys.decorSpots) ?? "").split(separator: ";") {
            let parts = entry.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let id = String(parts[0])
            let xy = parts[1].split(separator: ",")
            guard !id.isEmpty, xy.count == 2,
                  let x = Double(xy[0]), let y = Double(xy[1]) else { continue }
            spots[id] = CGPoint(x: x, y: y)
        }
        return spots
    }

    /// Owned decorations currently out of the water and off the bank.
    var decorStored: Set<String> { Set(defaults.stringArray(forKey: Keys.decorStored) ?? []) }

    var pondWater: String { defaults.string(forKey: Keys.pondWater) ?? "clear" }
    var pondShore: String { defaults.string(forKey: Keys.pondShore) ?? "meadow" }

    /// The saved ponds, by slot. A slot nothing was ever saved into decodes to
    /// an empty `PondLayout` rather than being absent, so the tab can draw three
    /// thumbnails without asking whether each one exists.
    var pondLayouts: [PondLayout] {
        (0..<PondCatalog.layoutSlots).map { PondLayout.decode(defaults.string(forKey: Keys.layout($0))) }
    }

    /// Hints remaining; irrelevant for premium owners, who have unlimited.
    var hintsLeft: Int { defaults.object(forKey: Keys.hintsLeft) as? Int ?? Self.freeHints }

    /// Levels a hint was already spent on: re-showing the glow there never
    /// solves again from scratch and never costs a second hint.
    var hintedLevels: Set<String> { Set(defaults.stringArray(forKey: Keys.hintedLevels) ?? []) }

    /// In-app language override; nil follows the device language.
    var language: Language? {
        defaults.string(forKey: Keys.language).flatMap(Language.init)
    }

    // MARK: - Writes

    func setHaptics(_ value: Bool) { defaults.set(value, forKey: Keys.haptics) }
    func setSelectedTheme(_ id: String) { defaults.set(id, forKey: Keys.theme) }
    func setSelectedSkin(_ id: String) { defaults.set(id, forKey: Keys.skin) }
    func setSelectedPad(_ id: String) { defaults.set(id, forKey: Keys.pad) }
    func setDebugTools(_ value: Bool) { defaults.set(value, forKey: Keys.debugTools) }
    func setUnlockAll(_ value: Bool) { defaults.set(value, forKey: Keys.unlockAll) }
    func setPondWeather(_ id: String) { defaults.set(id, forKey: Keys.pondWeather) }
    func setPondWater(_ id: String) { defaults.set(id, forKey: Keys.pondWater) }
    func setPondShore(_ id: String) { defaults.set(id, forKey: Keys.pondShore) }

    /// Saves the pond exactly as it stands into `slot`.
    ///
    /// `onPond` comes from the caller: which decoration is *owned* is a question
    /// this file cannot answer, since a golden pond can hand one over without it
    /// ever entering the owned set. Everything else is read here, so the
    /// snapshot is of a single moment.
    func savePondLayout(_ slot: Int, onPond: [String: CGPoint]) {
        let layout = PondLayout(
            weather: pondWeather,
            water: pondWater,
            shore: pondShore,
            friends: pondFriends,
            stored: decorStored,
            // Every dragged position, plus wherever the on-pond ones are
            // standing right now - including the ones still at their catalogue
            // anchor, which the stored map has never heard of.
            spots: decorSpots.merging(onPond) { _, new in new },
            inPond: Set(onPond.keys)
        )
        defaults.set(layout.encoded(), forKey: Keys.layout(slot))
    }

    /// Puts a saved pond back, or does nothing if the slot is empty.
    ///
    /// It restores what was *arranged*, never what is owned: everything that
    /// draws the pond already filters by ownership, so a stale name is simply
    /// not drawn, and comes back if the item is ever owned again.
    @discardableResult
    func applyPondLayout(_ slot: Int) -> Bool {
        let layout = PondLayout.decode(defaults.string(forKey: Keys.layout(slot)))
        guard !layout.isEmpty else { return false }
        restorePondLayout(layout)
        return true
    }

    /// Puts a pond back that was never in a slot - how Undo reverses a switch.
    func restorePondLayout(_ layout: PondLayout) {
        setPondWeather(layout.weather)
        setPondWater(layout.water)
        setPondShore(layout.shore)
        setPondFriends(layout.friends)
        setDecorStored(layout.stored)
        defaults.set(
            layout.spots.map { "\($0.key):\($0.value.x),\($0.value.y)" }.joined(separator: ";"),
            forKey: Keys.decorSpots
        )
    }

    func clearPondLayout(_ slot: Int) { defaults.removeObject(forKey: Keys.layout(slot)) }

    func setLanguage(_ language: Language?) {
        if let language {
            defaults.set(language.rawValue, forKey: Keys.language)
        } else {
            defaults.removeObject(forKey: Keys.language)
        }
    }

    func setHintsLeft(_ value: Int) { defaults.set(max(0, value), forKey: Keys.hintsLeft) }

    func setHintedLevels(_ levels: Set<String>) {
        defaults.set(Array(levels).sorted(), forKey: Keys.hintedLevels)
    }

    /// Records a purchase. Like on Android, purchases survive progress resets.
    func setOwned(_ products: Set<String>) {
        defaults.set(Array(products).sorted(), forKey: Keys.owned)
    }

    /// Records one owned product without disturbing the rest of the set.
    func grantProduct(_ productId: String) {
        setOwned(owned.union([productId]))
    }

    func setPondFriends(_ ids: [String]) {
        defaults.set(ids.joined(separator: ","), forKey: Keys.pondFriends)
    }

    /// Remembers where a decoration was dragged to.
    func setDecorSpot(id: String, at: CGPoint) {
        var spots = decorSpots
        spots[id] = at
        let encoded = spots
            .sorted { $0.key < $1.key }
            .map { "\($0.key):\($0.value.x),\($0.value.y)" }
            .joined(separator: ";")
        defaults.set(encoded, forKey: Keys.decorSpots)
    }

    /// Replaces the whole put-away set at once - used when a saved pond is
    /// restored, where the set arrives as a set rather than one id at a time.
    func setDecorStored(_ ids: Set<String>) {
        defaults.set(Array(ids).sorted(), forKey: Keys.decorStored)
    }

    /// Takes a decoration out of the pond, or puts it back.
    func setDecorStored(id: String, stored: Bool) {
        var now = decorStored
        if stored { now.insert(id) } else { now.remove(id) }
        defaults.set(Array(now).sorted(), forKey: Keys.decorStored)
    }

    /// Keeps the best result ever achieved for the level.
    func recordResult(levelId: String, stars: Int) {
        let key = Keys.stars(levelId)
        defaults.set(max(defaults.integer(forKey: key), stars), forKey: key)
    }

    /// Same, for a golden pond: the very first clear is what pays out its prize.
    ///
    /// The separate `bonusPaid` ledger keeps that exactly-once. Golden ponds used
    /// to hand over five hints here; they hand over a friend, a decoration or a
    /// lily pad now - a hint is spent and gone, and the pond you had to earn is
    /// not. Returns whether this was the first clear, so the win card knows to
    /// show the prize.
    func recordBonusResult(levelId: String, stars: Int) -> Bool {
        let key = Keys.stars(levelId)
        let previous = defaults.integer(forKey: key)
        var paid = Set(defaults.stringArray(forKey: Keys.bonusPaid) ?? [])
        var granted = false
        if previous == 0 && !paid.contains(levelId) {
            paid.insert(levelId)
            defaults.set(Array(paid).sorted(), forKey: Keys.bonusPaid)
            granted = true
        }
        defaults.set(max(previous, stars), forKey: key)
        return granted
    }

    /// Banks a Daily Pond clear for `epochDay` and pays it out, or returns nil
    /// if that day's pond was already cleared - the whole point of the daily is
    /// that it pays once.
    func recordDailyWin(epochDay: Int) -> DailyPayout? {
        let last = dailyLastDay
        guard last != epochDay else { return nil }
        let streak = nextDailyStreak(lastDay: last, epochDay: epochDay, storedStreak: dailyStreak)
        let best = max(dailyBestStreak, streak)
        let hints = dailyHintPayout(streak: streak)
        defaults.set(epochDay, forKey: Keys.dailyLastDay)
        defaults.set(streak, forKey: Keys.dailyStreak)
        defaults.set(best, forKey: Keys.dailyBestStreak)
        defaults.set(dailyTotal + 1, forKey: Keys.dailyTotal)
        setHintsLeft(hintsLeft + hints)
        return DailyPayout(hints: hints, streak: streak, isNewBestStreak: streak == best && streak > 1)
    }

    /// Keeps the best Splash Rush score for the duration.
    func recordRushBest(durationSec: Int, score: Int) {
        let key = Keys.rushBest(durationSec)
        defaults.set(max(defaults.integer(forKey: key), score), forKey: key)
    }

    /// Keeps the best score ever made in one of the pond's games.
    func recordMiniBest(gameId: String, score: Int) {
        let key = Keys.miniBest(gameId)
        defaults.set(max(defaults.integer(forKey: key), score), forKey: key)
    }

    // MARK: - Coins

    /// Spends `price` and, only if that succeeded, applies `effect` in the very
    /// same hop of the main actor. Everything coins buy goes through here: a
    /// purchase that debited but did not deliver - or delivered without debiting
    /// - would need a repair path, and there is no repair path.
    ///
    /// `derived` comes from the caller because only it knows the level list.
    @discardableResult
    private func spending(derived: Int, price: Int, effect: () -> Void) -> Bool {
        // Closed testing: the goods are handed over and the ledger is left
        // alone, so nothing is spent and the balance never moves. The price
        // itself is untouched - see `FreeMode`.
        if FreeMode.enabled {
            effect()
            return true
        }
        guard let after = CoinBank.spend(
            derived: derived, granted: coinsGranted, spent: coinsSpent, price: price
        ) else { return false }
        defaults.set(after, forKey: Keys.coinsSpent)
        effect()
        return true
    }

    /// Spends `price` coins, or refuses and writes nothing.
    @discardableResult
    func spendCoins(derived: Int, price: Int) -> Bool {
        spending(derived: derived, price: price) { }
    }

    /// Credits a bought coin pack. Like every purchase, coins survive a reset.
    func grantCoins(_ amount: Int) {
        defaults.set(coinsGranted + amount, forKey: Keys.coinsGranted)
    }

    /// Pays a mini game out against the week's ceiling and returns what it
    /// actually paid, which may be less than `want` and may be nothing at all.
    ///
    /// Rolling the week happens here rather than on a timer: a stamp that is not
    /// `week` means the stored total belongs to a week that has ended, so it is
    /// replaced rather than added to.
    @discardableResult
    func awardPondCoins(week: Int, want: Int) -> Int {
        let already = pondWeek == week ? pondWeekEarned : 0
        let give = CoinBank.pondPayout(alreadyThisWeek: already, want: want)
        defaults.set(week, forKey: Keys.pondWeek)
        defaults.set(already + give, forKey: Keys.pondWeekEarned)
        if give > 0 { grantCoins(give) }
        return give
    }

    /// Buys a shop item with coins, recording it in `owned` in the same write.
    @discardableResult
    func buyWithCoins(derived: Int, price: Int, productId: String) -> Bool {
        spending(derived: derived, price: price) { grantProduct(productId) }
    }

    /// Buys `count` hints with coins at `CoinBank.priceHint` each.
    @discardableResult
    func buyHints(derived: Int, count: Int) -> Bool {
        spending(derived: derived, price: count * CoinBank.priceHint) {
            setHintsLeft(hintsLeft + count)
        }
    }

    /// Buys the next seat at the pond. The price depends on how many seats are
    /// already there, so it is read here rather than passed in - otherwise two
    /// quick taps could both buy the sixth seat at the sixth seat's price and
    /// land on the eighth.
    @discardableResult
    func buyPondSlot(derived: Int) -> Bool {
        let extra = defaults.integer(forKey: Keys.pondSlots)
        guard let price = CoinBank.slotPrice(slots: CoinBank.baseSlots + extra) else { return false }
        if !FreeMode.enabled {
            guard let after = CoinBank.spend(
                derived: derived, granted: coinsGranted, spent: coinsSpent, price: price
            ) else { return false }
            defaults.set(after, forKey: Keys.coinsSpent)
        }
        defaults.set(extra + 1, forKey: Keys.pondSlots)
        return true
    }

    // MARK: - Reset

    /// Starts the whole game over, keeping only what was paid for with money.
    ///
    /// This used to clear the star map and little else, which left a "reset"
    /// player standing in a fully decorated pond with their friends still in it
    /// - and, worse, silently repossessed every level and golden-pond cosmetic
    /// anyway, because those are *derived* from the star map rather than stored.
    /// So the old reset both kept too much and took too much. It keeps exactly
    /// one thing now: the premium upgrade, and the coins someone bought.
    ///
    /// `coinsGranted` survives for that reason and `coinsSpent` is cleared with
    /// everything else, so a player gets back the coins they paid for rather
    /// than a balance already spent on items they no longer own.
    func resetProgress() {
        for level in Levels.all + Levels.bonusPonds {
            defaults.removeObject(forKey: Keys.stars(level.id))
        }
        for sec in Self.rushDurations { defaults.removeObject(forKey: Keys.rushBest(sec)) }
        for game in PondCatalog.games { defaults.removeObject(forKey: Keys.miniBest(game.id)) }

        // Everything bought with coins goes; everything bought with money
        // stays. That used to mean premium alone - it now also means the five
        // special friends, and a reset that repossessed a friend somebody paid
        // for would be a refund request, not a fresh start.
        setOwned(owned.filter { Catalog.moneyProductIds.contains($0) })

        defaults.removeObject(forKey: Keys.hintedLevels)
        defaults.removeObject(forKey: Keys.hintsLeft)

        // The daily run and the best streak both go: the streak's prizes are
        // cosmetics like any other, and leaving the streak behind would hand a
        // "fresh" save three friends it never earned.
        defaults.removeObject(forKey: Keys.dailyLastDay)
        defaults.removeObject(forKey: Keys.dailyStreak)
        defaults.removeObject(forKey: Keys.dailyBestStreak)
        defaults.removeObject(forKey: Keys.dailyTotal)

        // Golden ponds pay a cosmetic now rather than a one-off pile of hints,
        // so this ledger no longer needs to survive a reset - and keeping it
        // would mean re-clearing one silently, with no card.
        defaults.removeObject(forKey: Keys.bonusPaid)

        defaults.removeObject(forKey: Keys.coinsSpent)
        defaults.removeObject(forKey: Keys.pondWeek)
        defaults.removeObject(forKey: Keys.pondWeekEarned)

        // Back to a bare pond: nothing equipped, nothing placed, the starting
        // seats, and the default sky.
        defaults.removeObject(forKey: Keys.theme)
        defaults.removeObject(forKey: Keys.skin)
        defaults.removeObject(forKey: Keys.pad)
        defaults.removeObject(forKey: Keys.pondWeather)
        defaults.removeObject(forKey: Keys.pondFriends)
        defaults.removeObject(forKey: Keys.pondSlots)
        defaults.removeObject(forKey: Keys.decorSpots)
        defaults.removeObject(forKey: Keys.decorStored)
        defaults.removeObject(forKey: Keys.pondWater)
        defaults.removeObject(forKey: Keys.pondShore)
        // The saved ponds go with the pond they were saved from. Keeping them
        // would leave a "fresh" save one tap away from the fully decorated pond
        // the reset was supposed to clear.
        for slot in 0..<PondCatalog.layoutSlots { clearPondLayout(slot) }
    }
}
