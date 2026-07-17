//
//  ProgressStore.swift
//  PondPulse
//
//  UserDefaults-backed persistence, mirroring the Android ProgressRepository
//  key for key ("stars_1-4", "rush_best_60", "owned_products", ...) so the two
//  platforms stay comparable. Pure storage - AppViewModel owns the published
//  state and writes through here.
//

import Foundation

struct ProgressStore {

    /// Hints every install starts with; buying packs adds more.
    static let freeHints = 150

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
        static func stars(_ levelId: String) -> String { "stars_\(levelId)" }
        static func rushBest(_ durationSec: Int) -> String { "rush_best_\(durationSec)" }
    }

    /// Splash Rush durations offered, in seconds.
    static let rushDurations = [60, 180, 300]

    // MARK: - Reads

    var haptics: Bool {
        defaults.object(forKey: Keys.haptics) as? Bool ?? true
    }

    /// levelId -> stars (0 = unsolved).
    var stars: [String: Int] {
        Dictionary(uniqueKeysWithValues: Levels.all.map {
            ($0.id, defaults.integer(forKey: Keys.stars($0.id)))
        })
    }

    /// Product ids bought so far ("premium", "theme_sakura", "skin_koi", ...).
    var owned: Set<String> {
        Set(defaults.stringArray(forKey: Keys.owned) ?? [])
    }

    /// Splash Rush: durationSec -> best score (missing = never played).
    var rushBests: [Int: Int] {
        var bests: [Int: Int] = [:]
        for sec in Self.rushDurations where defaults.object(forKey: Keys.rushBest(sec)) != nil {
            bests[sec] = defaults.integer(forKey: Keys.rushBest(sec))
        }
        return bests
    }

    var selectedTheme: String { defaults.string(forKey: Keys.theme) ?? "dusk" }
    var selectedSkin: String { defaults.string(forKey: Keys.skin) ?? "duck" }
    var selectedPad: String { defaults.string(forKey: Keys.pad) ?? "lily" }

    /// Hints remaining; irrelevant for premium owners, who have unlimited.
    var hintsLeft: Int {
        defaults.object(forKey: Keys.hintsLeft) as? Int ?? Self.freeHints
    }

    /// Levels a hint was already spent on: re-showing the glow there never
    /// solves again from scratch and never costs a second hint.
    var hintedLevels: Set<String> {
        Set(defaults.stringArray(forKey: Keys.hintedLevels) ?? [])
    }

    /// In-app language override; nil follows the device language.
    var language: Language? {
        defaults.string(forKey: Keys.language).flatMap(Language.init)
    }

    // MARK: - Writes

    func setHaptics(_ value: Bool) { defaults.set(value, forKey: Keys.haptics) }
    func setSelectedTheme(_ id: String) { defaults.set(id, forKey: Keys.theme) }
    func setSelectedSkin(_ id: String) { defaults.set(id, forKey: Keys.skin) }
    func setSelectedPad(_ id: String) { defaults.set(id, forKey: Keys.pad) }

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

    /// Keeps the best result ever achieved for the level.
    func recordResult(levelId: String, stars: Int) {
        let key = Keys.stars(levelId)
        defaults.set(max(defaults.integer(forKey: key), stars), forKey: key)
    }

    /// Keeps the best Splash Rush score for the duration.
    func recordRushBest(durationSec: Int, score: Int) {
        let key = Keys.rushBest(durationSec)
        defaults.set(max(defaults.integer(forKey: key), score), forKey: key)
    }

    /// Clears stars and rush bests - purchases and cosmetics survive a reset.
    func resetProgress() {
        for level in Levels.all { defaults.removeObject(forKey: Keys.stars(level.id)) }
        for sec in Self.rushDurations { defaults.removeObject(forKey: Keys.rushBest(sec)) }
        defaults.removeObject(forKey: Keys.hintedLevels)
    }
}
