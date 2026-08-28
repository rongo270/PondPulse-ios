//
//  Strings.swift
//  PondPulse
//
//  Runtime-switchable localization, following the LineQuest pattern: every
//  player-facing string lives in generated lookup tables (L10nTables.swift)
//  keyed by the same names as Android's strings.xml, so parity checks line up.
//  English is the fallback for any missing key. Hebrew and Arabic flip the
//  whole layout right-to-left.
//

import SwiftUI

/// The languages the UI can be shown in, matching the Android in-app picker.
enum Language: String, CaseIterable, Identifiable {
    case en, de, es, fr, id, it, pl, pt, tr, ru, he, ar, hi, zh, ja, ko

    var id: String { rawValue }

    var isRTL: Bool { self == .he || self == .ar }

    /// The language's own name, shown in the language picker on purpose.
    var nativeName: String {
        switch self {
        case .en: "English"
        case .de: "Deutsch"
        case .es: "Español"
        case .fr: "Français"
        case .id: "Bahasa Indonesia"
        case .it: "Italiano"
        case .pl: "Polski"
        case .pt: "Português"
        case .tr: "Türkçe"
        case .ru: "Русский"
        case .he: "עברית"
        case .ar: "العربية"
        case .hi: "हिन्दी"
        case .zh: "中文"
        case .ja: "日本語"
        case .ko: "한국어"
        }
    }

    /// Best match for the device locale, used when no in-app override is set.
    static func deviceDefault(for locale: Locale = .current) -> Language {
        let code = locale.language.languageCode?.identifier ?? "en"
        switch code {
        case "iw": return .he // legacy Hebrew code
        case "in": return .id // legacy Indonesian code
        default: return Language(rawValue: code) ?? .en
        }
    }
}

/// Namespace the generated tables extend (`L10n.en`, `L10n.de`, …).
enum L10n {
    static let tables: [Language: [String: String]] = [
        .en: en, .de: de, .es: es, .fr: fr, .id: id, .it: it, .pl: pl, .pt: pt,
        .tr: tr, .ru: ru, .he: he, .ar: ar, .hi: hi, .zh: zh, .ja: ja, .ko: ko,
    ]

    /// iOS-only keys the Android strings.xml doesn't have yet (App Store
    /// requires an in-app restore button). Backport to Android when Play
    /// Billing lands, then move these into the generated tables.
    static let extras: [Language: [String: String]] = [
        .en: ["shop_restore": "Restore Purchases", "shop_restored": "Purchases restored"],
        .de: ["shop_restore": "Käufe wiederherstellen", "shop_restored": "Käufe wiederhergestellt"],
        .es: ["shop_restore": "Restaurar compras", "shop_restored": "Compras restauradas"],
        .fr: ["shop_restore": "Restaurer les achats", "shop_restored": "Achats restaurés"],
        .id: ["shop_restore": "Pulihkan pembelian", "shop_restored": "Pembelian dipulihkan"],
        .it: ["shop_restore": "Ripristina acquisti", "shop_restored": "Acquisti ripristinati"],
        .pl: ["shop_restore": "Przywróć zakupy", "shop_restored": "Zakupy przywrócone"],
        .pt: ["shop_restore": "Restaurar compras", "shop_restored": "Compras restauradas"],
        .tr: ["shop_restore": "Satın alımları geri yükle", "shop_restored": "Satın alımlar geri yüklendi"],
        .ru: ["shop_restore": "Восстановить покупки", "shop_restored": "Покупки восстановлены"],
        .he: ["shop_restore": "שחזור רכישות", "shop_restored": "הרכישות שוחזרו"],
        .ar: ["shop_restore": "استعادة المشتريات", "shop_restored": "تمت استعادة المشتريات"],
        .hi: ["shop_restore": "खरीदारी बहाल करें", "shop_restored": "खरीदारी बहाल हो गई"],
        .zh: ["shop_restore": "恢复购买", "shop_restored": "已恢复购买"],
        .ja: ["shop_restore": "購入を復元", "shop_restored": "購入を復元しました"],
        .ko: ["shop_restore": "구매 복원", "shop_restored": "구매가 복원되었습니다"],
    ]

    static func string(_ key: String, in language: Language) -> String {
        tables[language]?[key] ?? extras[language]?[key]
            ?? tables[.en]?[key] ?? extras[.en]?[key] ?? key
    }

    static let pluralTables: [Language: [String: [String: String]]] = [
        .en: enPlurals, .de: dePlurals, .es: esPlurals, .fr: frPlurals,
        .id: idPlurals, .it: itPlurals, .pl: plPlurals, .pt: ptPlurals,
        .tr: trPlurals, .ru: ruPlurals, .he: hePlurals, .ar: arPlurals,
        .hi: hiPlurals, .zh: zhPlurals, .ja: jaPlurals, .ko: koPlurals,
    ]

    /// The CLDR plural category `count` falls into for `language`.
    ///
    /// Swift has no plural selector of its own, and `stringsdict` is a
    /// compile-time bundle mechanism that cannot answer for a language the
    /// player picked in-app - which is the whole point of this table. So the
    /// rules for the sixteen shipped languages are written out. Anything not
    /// listed falls through to `other`, which every plurals block always
    /// defines, so an unhandled language degrades to a sentence rather than to
    /// a missing string.
    static func pluralCategory(_ count: Int, _ language: Language) -> String {
        let n = abs(count)
        switch language {
        // No grammatical plural at all.
        case .ja, .ko, .zh, .id:
            return "other"
        // one for exactly 1.
        case .en, .de, .es, .it, .tr:
            return n == 1 ? "one" : "other"
        // one for 0 and 1.
        case .fr, .hi, .pt:
            return n <= 1 ? "one" : "other"
        case .ru:
            if n % 10 == 1 && n % 100 != 11 { return "one" }
            if (2...4).contains(n % 10) && !(12...14).contains(n % 100) { return "few" }
            return "many"
        case .pl:
            if n == 1 { return "one" }
            if (2...4).contains(n % 10) && !(12...14).contains(n % 100) { return "few" }
            return "many"
        case .ar:
            if n == 0 { return "zero" }
            if n == 1 { return "one" }
            if n == 2 { return "two" }
            if (3...10).contains(n % 100) { return "few" }
            if (11...99).contains(n % 100) { return "many" }
            return "other"
        case .he:
            if n == 1 { return "one" }
            if n == 2 { return "two" }
            if n > 10 && n % 10 == 0 { return "many" }
            return "other"
        }
    }

    /// The plural form for `key` at `count`, falling back through the
    /// language's own `other` and then English.
    static func plural(_ key: String, count: Int, in language: Language) -> String {
        let category = pluralCategory(count, language)
        if let forms = pluralTables[language]?[key] {
            if let text = forms[category] { return text }
            if let text = forms["other"] { return text }
        }
        let english = pluralTables[.en]?[key]
        return english?[pluralCategory(count, .en)] ?? english?["other"] ?? key
    }
}

/// One language's view of every string; screens grab it from the environment.
struct Strings {
    let language: Language

    /// `strings["undo"]` - plain lookup by the Android key.
    subscript(_ key: String) -> String {
        L10n.string(key, in: language)
    }

    /// `strings["hint_left", hints]` - positional formatting (%1$d / %1$@).
    subscript(_ key: String, _ args: CVarArg...) -> String {
        String(format: L10n.string(key, in: language), arguments: args)
    }

    /// `strings.plural("daily_win_streak", streak)` - Android's <plurals>.
    /// The count is both the selector and the sole format argument, which is
    /// how every one of these is written.
    func plural(_ key: String, _ count: Int) -> String {
        String(format: L10n.plural(key, count: count, in: language), count)
    }
}

private struct StringsKey: EnvironmentKey {
    static let defaultValue = Strings(language: .en)
}

extension EnvironmentValues {
    var strings: Strings {
        get { self[StringsKey.self] }
        set { self[StringsKey.self] = newValue }
    }
}
