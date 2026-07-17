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
