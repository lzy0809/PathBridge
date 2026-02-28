# PathBridge

PathBridge 是一个 macOS Finder 到终端的效率工具。
核心目标是：在 Finder 工具栏点击一次图标，直接用你选定的终端打开当前目录。

## 功能特性

- Finder 工具栏一键打开当前目录到终端
- 可选择默认终端与打开方式（新窗口 / 新标签）
- 支持自定义命令模板（默认：`cd %PATH_QUOTED%; clear; pwd`）
- 支持简体中文 / English
- 支持打赏弹窗（双收款码）

## 当前支持终端

- Terminal
- iTerm2
- Warp
- WezTerm
- Ghostty
- Kaku

## 安装（普通用户）

1. 打开 [Releases](../../releases) 下载最新 `PathBridge-*.dmg`
2. 将 `PathBridgeApp.app` 拖入 `Applications`
3. 启动一次 PathBridge，点击界面内「一键添加到 Finder」
4. 如果系统拦截自动注入，按提示手动 `Command + 拖拽` 到 Finder 工具栏

## 首次使用说明

- 点击 Finder 工具栏 PathBridge 图标会直接打开终端，不会弹设置窗口。
- 从 Launchpad/Dock 启动 PathBridge，会打开设置界面。
- 若遇到 Finder 自动化权限提示，请在系统设置中允许 PathBridge/PathBridgeLauncher 控制 Finder。

## 开发环境

```bash
tuist install
tuist generate
open PathBridge.xcworkspace
```

推荐使用 scheme：

- `PathBridgeApp`（主设置界面 + 联调）
- `PathBridgeLauncher`（Finder 工具栏执行体联调）

## 本地打包 DMG

无签名本地包：

```bash
scripts/release/make_dmg.sh
```

带签名/公证流程见：

- `docs/signing-and-dmg.md`

## Homebrew 安装（规划）

计划通过自定义 tap 分发：`lzy9527/homebrew-tap`

未来安装命令：

```bash
brew tap lzy9527/homebrew-tap
brew install --cask pathbridge
```

## 开源发布自动化

```bash
scripts/release/publish_open_source.sh \
  --version 0.1.0 \
  --dmg build/release/dmg/PathBridge-xxxx.dmg
```

## 架构概览

- `PathBridgeApp`：设置 UI 与安装引导
- `PathBridgeLauncher`：无 Dock 的工具栏执行体（LSUIElement）
- `Packages/TerminalAdapters`：终端适配层
- `Packages/Core`：路径归一化等核心逻辑
- `Packages/Shared`：设置模型、通知、通用组件

## License

MIT
