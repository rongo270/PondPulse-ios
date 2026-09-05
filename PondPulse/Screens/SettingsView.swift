//
//  SettingsView.swift
//  PondPulse
//
//  Haptics, the testing tools, the in-app language picker (16 languages,
//  RTL-aware) and the progress reset. Port of the Android ui/SettingsScreen.kt;
//  the language choice applies instantly instead of recreating the activity.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    @State private var confirmReset = false
    @State private var pickLanguage = false
    @State private var picking: CosmeticKind?

    /// Testing tools. A debug build has always had them; a release build only
    /// does while `FreeMode.enabled`, which is what a closed-testing build is.
    /// Turning that flag off takes the whole section out again, so a shipped
    /// pond can never grow a level skipper. `FreeMode.unlockable` is the same
    /// question the switch itself is gated on, asked once.
    private var showsTesting: Bool { FreeMode.unlockable }

    /// The closed-testing line is only true while the flag is on. With the
    /// economy live, a debug build still has the tools, and the switch below is
    /// what makes it free - the build itself is not.
    private var testingDescKey: String {
        FreeMode.enabled ? "settings_testing_desc" : "settings_testing_desc_debug"
    }

    /// In a debug build the skipper is a developer tool; in a closed-testing
    /// release it is the one thing a tester is being handed.
    private var skipperDescKey: String {
        #if DEBUG
        return "settings_debug_desc"
        #else
        return "settings_skipper_desc"
        #endif
    }

    var body: some View {
        content
            .pondContentWidth()
    }

    /// One "what my pond looks like" row: a thumbnail of what is equipped, what
    /// it is called, and a tap to change it.
    private func cosmeticRow(_ kind: CosmeticKind) -> some View {
        Button {
            picking = kind
        } label: {
            HStack(spacing: 14) {
                kind.preview(vm)
                    .frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text(strings[kind.titleKey])
                        .font(.game(15, .semibold))
                        .foregroundStyle(palette.textPrimary)
                    Text(strings[kind.equippedNameKey(vm)])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: strings["settings_title"], onBack: { vm.back() })

            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 0) {
                        // First on the screen, and it carries its own flag.
                        // A player who has the game in a language they cannot
                        // read cannot read "Language" either - the flag is the
                        // one thing on this screen that says what it says
                        // without being read, so it has to be somewhere they
                        // will find it before they give up, which is the top.
                        Button {
                            pickLanguage = true
                        } label: {
                            HStack(spacing: 14) {
                                Text(vm.languageOverride?.flag ?? Language.systemFlag)
                                    .font(.system(size: 26))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(strings["settings_language"])
                                        .font(.game(15, .semibold))
                                        .foregroundStyle(palette.textPrimary)
                                    Text(vm.languageOverride?.nativeName ?? strings["settings_language_system"])
                                        .font(.game(12))
                                        .foregroundStyle(palette.textSecondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.forward")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(palette.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider()
                            .overlay(palette.textSecondary.opacity(0.15))
                            .padding(.vertical, 14)

                        // What the pond looks like, in three rows.
                        //
                        // Deliberately only a switcher: it lists what the player
                        // already has and nothing else. Browsing, prices and
                        // everything still locked belong in the shop, and a
                        // second shop in Settings would be two places to keep
                        // honest. This is for the player who wants their Frog
                        // back without going shopping for it.
                        ForEach(CosmeticKind.allCases) { kind in
                            cosmeticRow(kind)
                            if kind != CosmeticKind.allCases.last {
                                Divider()
                                    .overlay(palette.textSecondary.opacity(0.15))
                                    .padding(.vertical, 12)
                            }
                        }

                        Divider()
                            .overlay(palette.textSecondary.opacity(0.15))
                            .padding(.vertical, 14)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(strings["settings_haptics"])
                                    .font(.game(15, .semibold))
                                    .foregroundStyle(palette.textPrimary)
                                Text(strings["settings_haptics_desc"])
                                    .font(.game(12))
                                    .foregroundStyle(palette.textSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(get: { vm.haptics }, set: { vm.setHaptics($0) }))
                                .labelsHidden()
                                .tint(palette.accent)
                        }
                        .padding(.bottom, 14)

                        if showsTesting {
                            Divider().overlay(palette.textSecondary.opacity(0.15))

                            VStack(alignment: .leading, spacing: 0) {
                                Text(strings["settings_testing"])
                                    .font(.game(14, .bold))
                                    .foregroundStyle(palette.accent)
                                Text(strings[testingDescKey])
                                    .font(.game(12))
                                    .foregroundStyle(palette.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.bottom, 12)

                                settingToggle(
                                    title: strings["settings_unlock_all"],
                                    desc: strings["settings_unlock_all_desc"],
                                    isOn: Binding(get: { vm.unlockAllFlag }, set: { vm.setUnlockAll($0) })
                                )
                                settingToggle(
                                    title: strings["settings_debug"],
                                    desc: strings[skipperDescKey],
                                    isOn: Binding(get: { vm.debugTools }, set: { vm.setDebugTools($0) })
                                )
                                .padding(.top, 12)

                                // Three grants rather than a second switch. The
                                // switch above turns the economy off, which is
                                // the one thing you cannot do while you are
                                // trying to look at it: with everything free,
                                // every price on every shelf stops meaning
                                // anything. These hand over a specific thing at
                                // the real price and leave the rest alone.
                                Text(strings["settings_grants_desc"])
                                    .font(.game(12))
                                    .foregroundStyle(palette.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, 16)

                                HStack(spacing: 8) {
                                    grantButton(
                                        icon: "circle.hexagongrid.fill",
                                        title: strings["settings_grant_coins", 500]
                                    ) { vm.testGrantCoins() }
                                    grantButton(
                                        icon: "pawprint.fill",
                                        title: strings["settings_grant_friends"]
                                    ) { vm.testGrantFriends() }
                                    grantButton(
                                        icon: "plus.circle.fill",
                                        title: strings["settings_grant_seats", 2]
                                    ) { vm.testGrantPondSlots() }
                                }
                                .padding(.top, 10)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 14)
                            .padding(.bottom, 14)
                        }

                    }
                    .padding(20)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strings["settings_reset"])
                                .font(.game(15, .semibold))
                                .foregroundStyle(palette.danger)
                            Text(strings["settings_reset_desc"])
                                .font(.game(12))
                                .foregroundStyle(palette.textSecondary)
                        }
                        Spacer()
                        Button(strings["settings_reset_confirm_yes"]) { confirmReset = true }
                            .font(.game(14, .bold))
                            .foregroundStyle(palette.danger)
                    }
                    .padding(20)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Text(strings["settings_about"])
                        .font(.game(12))
                        .foregroundStyle(palette.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 12)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(item: $picking) { kind in
            CosmeticPicker(vm: vm, kind: kind) { picking = nil }
                .environment(\.palette, palette)
                .environment(\.strings, strings)
        }
        .sheet(isPresented: $pickLanguage) {
            LanguagePicker(current: vm.languageOverride) { language in
                vm.setLanguage(language)
                pickLanguage = false
            }
            .presentationDetents([.medium, .large])
        }
        .alert(strings["settings_reset_confirm_title"], isPresented: $confirmReset) {
            Button(strings["settings_reset_confirm_yes"], role: .destructive) {
                vm.resetProgress()
            }
            Button(strings["settings_reset_confirm_no"], role: .cancel) {}
        } message: {
            Text(strings["settings_reset_confirm_body"])
        }
    }
}

extension SettingsView {
    fileprivate func settingToggle(title: String, desc: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.game(15, .semibold))
                    .foregroundStyle(palette.textPrimary)
                Text(desc)
                    .font(.game(12))
                    .foregroundStyle(palette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(palette.accent)
        }
    }

    /// One testing grant: a tap that hands over a specific thing and says so.
    ///
    /// Deliberately not a toggle. A toggle asks to be turned back off and these
    /// cannot be - coins have been banked and friends have been handed over -
    /// so a switch that would not switch back is a worse lie than a button.
    fileprivate func grantButton(
        icon: String, title: String, action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
            Haptics.tick(enabled: vm.haptics)
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(palette.accent)
                Text(title)
                    .font(.game(11, .semibold))
                    .foregroundStyle(palette.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 6)
            .background(palette.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(palette.accent.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(SquishyButtonStyle())
    }
}

private struct LanguagePicker: View {
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let current: Language?
    let onPick: (Language?) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(strings["settings_language"])
                    .font(.game(20, .bold))
                    .foregroundStyle(palette.textPrimary)
                    .padding(.top, 24)
                    .padding(.bottom, 10)
                row(
                    flag: Language.systemFlag,
                    name: strings["settings_language_system"],
                    selected: current == nil
                ) { onPick(nil) }
                ForEach(Language.allCases) { language in
                    row(
                        flag: language.flag,
                        name: language.nativeName,
                        selected: language == current
                    ) { onPick(language) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationBackground(palette.surfaceHigh)
    }

    private func row(
        flag: String,
        name: String,
        selected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack {
                // A fixed width, so seventeen names start on the same line
                // whatever the flag beside them is - the emoji font draws some
                // of them wider than others.
                Text(flag)
                    .font(.system(size: 22))
                    .frame(width: 40, alignment: .leading)
                Text(name)
                    .font(.game(16, selected ? .bold : .regular))
                    .foregroundStyle(selected ? palette.accent : palette.textPrimary)
                Spacer()
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(palette.accent)
                }
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Changing what the pond looks like

/// The three things Settings can switch: the theme, the lily pad, the friend.
///
/// Named with the shop's own three headings rather than new ones, so the row a
/// player taps here and the shelf they end up on are called the same thing.
enum CosmeticKind: String, CaseIterable, Identifiable {
    case theme, pad, friend

    var id: String { rawValue }

    var titleKey: String {
        switch self {
        case .theme: return "shop_section_themes"
        case .pad: return "shop_section_pads"
        case .friend: return "shop_section_skins"
        }
    }

    /// The shelf the picker's "find more" button opens.
    var shelf: Shelf {
        switch self {
        case .theme: return .themes
        case .pad: return .pads
        case .friend: return .friends
        }
    }

    /// The name of whatever is equipped right now.
    func equippedNameKey(_ vm: AppViewModel) -> String {
        switch self {
        case .theme: return Catalog.themeById(vm.themeId).nameKey
        case .pad: return Catalog.padById(vm.padId).nameKey
        case .friend: return Catalog.skinById(vm.skinId).nameKey
        }
    }

    /// A thumbnail of what is equipped right now.
    ///
    /// The theme gets a swatch rather than `ThemePreview`. That draws a whole
    /// little pond, which is right at shelf size and useless at 34pt - beside
    /// the friend row it was a second, blurrier duckling. What a theme is at
    /// this size is its colours.
    @ViewBuilder func preview(_ vm: AppViewModel) -> some View {
        switch self {
        case .theme: ThemeSwatch(palette: Catalog.themeById(vm.themeId).palette)
        case .pad: PadPreview(padId: vm.padId)
        case .friend: SkinPreview(skinId: vm.skinId)
        }
    }

    /// Everything of this kind the player can actually equip, in shelf order.
    ///
    /// Owned only. A picker that listed the locked ones too would be the shop
    /// with the prices taken off - and a row you tap that does nothing is worse
    /// than a row that is not there. What is missing is one button away.
    func owned(_ vm: AppViewModel) -> [(id: String, nameKey: String)] {
        switch self {
        case .theme:
            return Catalog.themes
                .filter { vm.isOwned($0.unlock, productId: Catalog.themeProductId($0.id)) }
                .map { ($0.id, $0.nameKey) }
        case .pad:
            return Catalog.pads
                .filter { vm.isOwned($0.unlock, productId: Catalog.padProductId($0.id)) }
                .map { ($0.id, $0.nameKey) }
        case .friend:
            return Catalog.skins
                .filter { vm.isOwned($0.unlock, productId: Catalog.skinProductId($0.id)) }
                .map { ($0.id, $0.nameKey) }
        }
    }

    func isEquipped(_ id: String, _ vm: AppViewModel) -> Bool {
        switch self {
        case .theme: return vm.themeId == id
        case .pad: return vm.padId == id
        case .friend: return vm.skinId == id
        }
    }

    func equip(_ id: String, _ vm: AppViewModel) {
        switch self {
        case .theme: vm.selectTheme(id)
        case .pad: vm.selectPad(id)
        case .friend: vm.selectSkin(id)
        }
    }

    @ViewBuilder func tile(_ id: String) -> some View {
        switch self {
        case .theme: ThemePreview(palette: Catalog.themeById(id).palette)
        case .pad: PadPreview(padId: id)
        case .friend: SkinPreview(skinId: id)
        }
    }
}

/// A theme at thumbnail size: its water, its ground and its accent.
struct ThemeSwatch: View {
    let palette: PondPalette

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [palette.water, palette.waterDeep],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(palette.accent)
                .frame(width: 11, height: 11)
                .padding(4)
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(palette.background, lineWidth: 2)
        }
    }
}

/// A grid of everything the player owns of one kind. Tap to equip; the sheet
/// stays up, so trying three friends in a row is three taps rather than nine.
private struct CosmeticPicker: View {
    @ObservedObject var vm: AppViewModel
    @Environment(\.palette) private var palette
    @Environment(\.strings) private var strings
    let kind: CosmeticKind
    let onClose: () -> Void

    private let columns = [GridItem(.adaptive(minimum: 84), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text(strings[kind.titleKey])
                    .font(.game(20, .bold))
                    .foregroundStyle(palette.textPrimary)
                    .padding(.top, 24)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(kind.owned(vm), id: \.id) { item in
                        RosterTile(
                            name: strings[item.nameKey],
                            lockLabel: nil,
                            selected: kind.isEquipped(item.id, vm),
                            onTap: { kind.equip(item.id, vm) }
                        ) {
                            kind.tile(item.id).aspectRatio(1, contentMode: .fit)
                        }
                    }
                }

                // The rest of the collection lives in the shop, and this is the
                // only thing in the picker that leaves it.
                //
                // The hop is not decoration: navigating swaps the whole root
                // view, and doing that in the same turn as dismissing the sheet
                // tears the sheet's host out from under its own dismissal.
                Button {
                    onClose()
                    DispatchQueue.main.async { vm.navigate(.shopShelf(kind.shelf)) }
                } label: {
                    Text(strings["collection_open_shop"])
                        .font(.game(15, .bold))
                        .foregroundStyle(palette.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationBackground(palette.surfaceHigh)
    }
}
