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

    /// The globe stands for "whatever the phone is set to" - no country owns that.
    static let systemFlag = "🌐"

    /// The flag beside the name in the picker.
    ///
    /// Sixteen names in sixteen scripts is a wall of text to a player who cannot
    /// read fifteen of them, and a flag is recognisable before the word beside
    /// it has been read at all. A language is not a country, so these are the
    /// flags Android's own picker uses rather than an argument about which one
    /// each language belongs to.
    var flag: String {
        switch self {
        case .en: "🇬🇧"
        case .de: "🇩🇪"
        case .es: "🇪🇸"
        case .fr: "🇫🇷"
        case .id: "🇮🇩"
        case .it: "🇮🇹"
        case .pl: "🇵🇱"
        case .pt: "🇵🇹"
        case .tr: "🇹🇷"
        case .ru: "🇷🇺"
        case .he: "🇮🇱"
        case .ar: "🇸🇦"
        case .hi: "🇮🇳"
        case .zh: "🇨🇳"
        case .ja: "🇯🇵"
        case .ko: "🇰🇷"
        }
    }

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
    /// requires an in-app restore button; the reset asks twice here). Backport
    /// to Android when Play Billing lands, then move these into the generated
    /// tables.
    static let extras: [Language: [String: String]] = [
        .en: ["shop_restore": "Restore Purchases", "shop_restored": "Purchases restored",
              "settings_reset_continue": "Continue",
              "settings_reset_confirm2_title": "Are you sure?",
              "settings_reset_confirm2_body": "This erases your pond, your stars and your coins. It cannot be undone.",
              "settings_reset_confirm2_yes": "Erase everything"
        ],
        .de: ["shop_restore": "Käufe wiederherstellen", "shop_restored": "Käufe wiederhergestellt",
              "settings_reset_continue": "Weiter",
              "settings_reset_confirm2_title": "Bist du sicher?",
              "settings_reset_confirm2_body": "Das löscht deinen Teich, deine Sterne und deine Münzen. Es lässt sich nicht rückgängig machen.",
              "settings_reset_confirm2_yes": "Alles löschen"
        ],
        .es: ["shop_restore": "Restaurar compras", "shop_restored": "Compras restauradas",
              "settings_reset_continue": "Continuar",
              "settings_reset_confirm2_title": "¿Seguro?",
              "settings_reset_confirm2_body": "Esto borra tu estanque, tus estrellas y tus monedas. No se puede deshacer.",
              "settings_reset_confirm2_yes": "Borrar todo"
        ],
        .fr: ["shop_restore": "Restaurer les achats", "shop_restored": "Achats restaurés",
              "settings_reset_continue": "Continuer",
              "settings_reset_confirm2_title": "Tu es sûr ?",
              "settings_reset_confirm2_body": "Cela efface ton étang, tes étoiles et tes pièces. C’est irréversible.",
              "settings_reset_confirm2_yes": "Tout effacer"
        ],
        .id: ["shop_restore": "Pulihkan pembelian", "shop_restored": "Pembelian dipulihkan",
              "settings_reset_continue": "Lanjut",
              "settings_reset_confirm2_title": "Yakin?",
              "settings_reset_confirm2_body": "Ini menghapus kolam, bintang, dan koinmu. Tidak bisa dibatalkan.",
              "settings_reset_confirm2_yes": "Hapus semua"
        ],
        .it: ["shop_restore": "Ripristina acquisti", "shop_restored": "Acquisti ripristinati",
              "settings_reset_continue": "Continua",
              "settings_reset_confirm2_title": "Sei sicuro?",
              "settings_reset_confirm2_body": "Questo cancella il tuo stagno, le tue stelle e le tue monete. Non si può annullare.",
              "settings_reset_confirm2_yes": "Cancella tutto"
        ],
        .pl: ["shop_restore": "Przywróć zakupy", "shop_restored": "Zakupy przywrócone",
              "settings_reset_continue": "Dalej",
              "settings_reset_confirm2_title": "Na pewno?",
              "settings_reset_confirm2_body": "To skasuje twój staw, gwiazdki i monety. Tego nie da się cofnąć.",
              "settings_reset_confirm2_yes": "Skasuj wszystko"
        ],
        .pt: ["shop_restore": "Restaurar compras", "shop_restored": "Compras restauradas",
              "settings_reset_continue": "Continuar",
              "settings_reset_confirm2_title": "Tens a certeza?",
              "settings_reset_confirm2_body": "Isto apaga o teu lago, as tuas estrelas e as tuas moedas. Não pode ser desfeito.",
              "settings_reset_confirm2_yes": "Apagar tudo"
        ],
        .tr: ["shop_restore": "Satın alımları geri yükle", "shop_restored": "Satın alımlar geri yüklendi",
              "settings_reset_continue": "Devam",
              "settings_reset_confirm2_title": "Emin misin?",
              "settings_reset_confirm2_body": "Bu; göletini, yıldızlarını ve altınlarını siler. Geri alınamaz.",
              "settings_reset_confirm2_yes": "Her şeyi sil"
        ],
        .ru: ["shop_restore": "Восстановить покупки", "shop_restored": "Покупки восстановлены",
              "settings_reset_continue": "Продолжить",
              "settings_reset_confirm2_title": "Вы уверены?",
              "settings_reset_confirm2_body": "Это сотрёт ваш пруд, звёзды и монеты. Отменить будет нельзя.",
              "settings_reset_confirm2_yes": "Стереть всё"
        ],
        .he: ["shop_restore": "שחזור רכישות", "shop_restored": "הרכישות שוחזרו",
              "settings_reset_continue": "להמשיך",
              "settings_reset_confirm2_title": "בטוחים?",
              "settings_reset_confirm2_body": "זה מוחק את הבריכה, הכוכבים והמטבעות שלכם. אי אפשר לבטל.",
              "settings_reset_confirm2_yes": "למחוק הכול"
        ],
        .ar: ["shop_restore": "استعادة المشتريات", "shop_restored": "تمت استعادة المشتريات",
              "settings_reset_continue": "متابعة",
              "settings_reset_confirm2_title": "هل أنت متأكد؟",
              "settings_reset_confirm2_body": "سيمحو هذا بركتك ونجومك وعملاتك. لا يمكن التراجع.",
              "settings_reset_confirm2_yes": "امحُ كل شيء"
        ],
        .hi: ["shop_restore": "खरीदारी बहाल करें", "shop_restored": "खरीदारी बहाल हो गई",
              "settings_reset_continue": "जारी रखें",
              "settings_reset_confirm2_title": "क्या आप निश्चित हैं?",
              "settings_reset_confirm2_body": "इससे आपका तालाब, सितारे और सिक्के मिट जाएंगे। इसे पलटा नहीं जा सकता।",
              "settings_reset_confirm2_yes": "सब कुछ मिटाएँ"
        ],
        .zh: ["shop_restore": "恢复购买", "shop_restored": "已恢复购买",
              "settings_reset_continue": "继续",
              "settings_reset_confirm2_title": "确定吗？",
              "settings_reset_confirm2_body": "这会清空你的池塘、星星和金币，并且无法撤销。",
              "settings_reset_confirm2_yes": "全部清空"
        ],
        .ja: ["shop_restore": "購入を復元", "shop_restored": "購入を復元しました",
              "settings_reset_continue": "続ける",
              "settings_reset_confirm2_title": "本当によろしいですか？",
              "settings_reset_confirm2_body": "池も星もコインも消えます。元には戻せません。",
              "settings_reset_confirm2_yes": "すべて消去"
        ],
        .ko: ["shop_restore": "구매 복원", "shop_restored": "구매가 복원되었습니다",
              "settings_reset_continue": "계속",
              "settings_reset_confirm2_title": "정말 초기화할까요?",
              "settings_reset_confirm2_body": "연못과 별, 코인이 모두 지워집니다. 되돌릴 수 없습니다.",
              "settings_reset_confirm2_yes": "전부 지우기"
        ],
    ]

    static func string(_ key: String, in language: Language) -> String {
        tables[language]?[key] ?? extras[language]?[key]
            ?? tables[.en]?[key] ?? extras[.en]?[key] ?? key
    }

    static let arrayTables: [Language: [String: [String]]] = [
        .en: enArrays, .de: deArrays, .es: esArrays, .fr: frArrays,
        .id: idArrays, .it: itArrays, .pl: plArrays, .pt: ptArrays,
        .tr: trArrays, .ru: ruArrays, .he: heArrays, .ar: arArrays,
        .hi: hiArrays, .zh: zhArrays, .ja: jaArrays, .ko: koArrays,
    ]

    /// Android's `<string-array>`. Empty is never a valid answer - a caller
    /// picks a line out of one of these - so a language missing the key falls
    /// through to English rather than handing back nothing to draw.
    static func array(_ key: String, in language: Language) -> [String] {
        if let items = arrayTables[language]?[key], !items.isEmpty { return items }
        return arrayTables[.en]?[key] ?? []
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

    /// `strings.array("win_titles")` - Android's <string-array>, in order.
    func array(_ key: String) -> [String] {
        L10n.array(key, in: language)
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
