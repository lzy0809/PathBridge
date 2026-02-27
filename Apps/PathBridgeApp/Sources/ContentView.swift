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
    }

    private var header: some View {
        VStack(spacing: 2) {
            Text("PathBridge")
                .font(.system(size: 34, weight: .semibold))
            Text("Finder to Terminal")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }

    private var settingsForm: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Terminal application to use:")
                .font(.system(size: 14, weight: .medium))
            Picker("", selection: $settingsViewModel.defaultTerminalID) {
                ForEach(settingsViewModel.terminalOptions) { option in
                    Text(option.isInstalled ? option.displayName : "\(option.displayName) (未安装)")
                        .tag(option.id)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)

            Text("Open terminal in:")
                .font(.system(size: 14, weight: .medium))
            Picker("", selection: $settingsViewModel.defaultOpenMode) {
                Text("New Window").tag(OpenMode.newWindow)
                Text("New Tab").tag(OpenMode.newTab)
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity)

            Text("Command to execute in terminal:")
                .font(.system(size: 14, weight: .medium))
            HStack(spacing: 8) {
                TextField("cd %PATH_QUOTED%; clear; pwd", text: $settingsViewModel.commandTemplate)
                    .textFieldStyle(.roundedBorder)

                Button {
                    settingsViewModel.restoreDefaultCommandTemplate()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .help("恢复默认命令模板")
            }

            Text("%PATH_QUOTED% 会替换为 Finder 当前目录。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var installSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.orange)

                Text(extensionGuideViewModel.statusMessage)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.orange)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 9)
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

            Button("Add PathBridge button to Finder Toolbar") {
                extensionGuideViewModel.installToFinderToolbar()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
    }

    private var supportSection: some View {
        Button("Thank The Developers") {
            showSupportSheet = true
        }
        .buttonStyle(.bordered)
        .frame(maxWidth: .infinity)
    }

    private var supportSheet: some View {
        VStack(spacing: 12) {
            Text("感谢支持")
                .font(.headline)

            HStack(alignment: .top, spacing: 14) {
                ForEach(supportViewModel.qrcodes) { code in
                    VStack(spacing: 6) {
                        if let image = supportViewModel.image(for: code) {
                            Image(nsImage: image)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(width: 150, height: 150)
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.secondary.opacity(0.2))
                                .frame(width: 150, height: 150)
                        }

                        Text(code.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("关闭") {
                showSupportSheet = false
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .frame(minWidth: 380, minHeight: 280)
    }
}
