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

    /// Testing tools. A debug build has always had them; a release build only
    /// does while `FreeMode.enabled`, which is what a closed-testing build is.
    /// Turning that flag off takes the whole section out again, so a shipped
    /// pond can never grow a level skipper.
    private var showsTesting: Bool {
        #if DEBUG
        return true
        #else
        return FreeMode.enabled
        #endif
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

    private var content: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: strings["settings_title"], onBack: { vm.back() })

            ScrollView {
                VStack(spacing: 12) {
                    VStack(spacing: 0) {
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
                                Text(strings["settings_testing_desc"])
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
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 14)
                            .padding(.bottom, 14)
                        }

                        Divider().overlay(palette.textSecondary.opacity(0.15))

                        Button {
                            pickLanguage = true
                        } label: {
                            HStack {
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
                            .padding(.top, 14)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
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
                row(name: strings["settings_language_system"], selected: current == nil) { onPick(nil) }
                ForEach(Language.allCases) { language in
                    row(name: language.nativeName, selected: language == current) { onPick(language) }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationBackground(palette.surfaceHigh)
    }

    private func row(name: String, selected: Bool, onTap: @escaping () -> Void) -> some View {
        Button(action: onTap) {
            HStack {
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
