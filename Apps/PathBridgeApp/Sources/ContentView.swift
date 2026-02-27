import PathBridgeShared
import SwiftUI

struct ContentView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var extensionGuideViewModel = ExtensionGuideViewModel()
    @StateObject private var supportViewModel = SupportViewModel()
    @State private var showSupportSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            settingsForm
            installSection
            supportSection
        }
        .padding(14)
        .frame(minWidth: 400, idealWidth: 430, maxWidth: 470, minHeight: 330, idealHeight: 360)
        .sheet(isPresented: $showSupportSheet) {
            supportSheet
        }
        .onChange(of: settingsViewModel.defaultTerminalID) { _, _ in settingsViewModel.save() }
        .onChange(of: settingsViewModel.defaultOpenMode) { _, _ in settingsViewModel.save() }
        .onChange(of: settingsViewModel.commandTemplate) { _, _ in settingsViewModel.save() }
        .onChange(of: settingsViewModel.appLanguage) { _, _ in settingsViewModel.saveLanguage() }
    }

    private var header: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 2) {
                Text("PathBridge")
                    .font(.system(size: 34, weight: .semibold))
                Text(t(.finderToTerminal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.8))
            }
            .frame(maxWidth: .infinity)

            Picker(t(.language), selection: $settingsViewModel.appLanguage) {
                ForEach(AppLanguage.allCases) { language in
                    Text(language.pickerLabel).tag(language)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 74)
            .padding(.top, 10)
        }
    }

    private var settingsForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t(.terminalApplicationToUse))
                .font(.system(size: 14, weight: .medium))
            Picker("", selection: $settingsViewModel.defaultTerminalID) {
                ForEach(settingsViewModel.terminalOptions) { option in
                    Text(AppLocalizer.terminalLabel(option.displayName, installed: option.isInstalled, language: settingsViewModel.appLanguage))
                        .tag(option.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)

            Text(t(.openTerminalIn))
                .font(.system(size: 14, weight: .medium))
            Picker("", selection: $settingsViewModel.defaultOpenMode) {
                Text(t(.newWindow)).tag(OpenMode.newWindow)
                Text(t(.newTab)).tag(OpenMode.newTab)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)

            Text(t(.commandToExecute))
                .font(.system(size: 14, weight: .medium))
            HStack(spacing: 8) {
                TextField(t(.commandPlaceholder), text: $settingsViewModel.commandTemplate)
                    .textFieldStyle(.roundedBorder)

                Button {
                    settingsViewModel.restoreDefaultCommandTemplate()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .help(t(.restoreDefaultCommand))
            }

            Text(t(.commandHint))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var installSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.orange)

                Text(AppLocalizer.installGuideMessage(language: settingsViewModel.appLanguage, state: extensionGuideViewModel.state))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.orange)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.orange.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.orange.opacity(0.45), lineWidth: 1)
            )

            Button(t(.addToFinderButton)) {
                extensionGuideViewModel.installToFinderToolbar()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
    }

    private var supportSection: some View {
        Button(t(.thankTheDevelopers)) {
            showSupportSheet = true
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
        .padding(.bottom, 8)
    }

    private var supportSheet: some View {
        VStack(spacing: 12) {
            Text(t(.supportTitle))
                .font(.headline)

            HStack(alignment: .top, spacing: 16) {
                ForEach(supportViewModel.qrcodes) { code in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.12))
                            if let image = supportViewModel.image(for: code) {
                                VStack {
                                    Image(nsImage: image)
                                        .resizable()
                                        .interpolation(.high)
                                        .scaledToFit()
                                        .frame(maxWidth: 220, maxHeight: 300, alignment: .top)
                                    Spacer(minLength: 0)
                                }
                                .padding(8)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.secondary.opacity(0.2))
                                    .frame(width: 220, height: 280)
                            }
                        }
                        .frame(width: 236, height: 318)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                        )

                        Text(supportViewModel.localizedTitle(for: code, language: settingsViewModel.appLanguage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 236)
                }
            }

            Button(t(.close)) {
                showSupportSheet = false
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .frame(minWidth: 540, minHeight: 420)
    }

    private func t(_ key: AppLocalizerKey) -> String {
        AppLocalizer.text(key, language: settingsViewModel.appLanguage)
    }
}
