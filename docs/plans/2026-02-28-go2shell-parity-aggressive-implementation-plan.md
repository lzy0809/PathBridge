# Go2Shell Parity Aggressive Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 PathBridge 重构为与 Go2Shell 同构的“设置 App + 内嵌 LSUIElement Helper”架构，并产出可安装 DMG。

**Architecture:** 主 App 仅承载设置 UI 与安装引导；Finder 工具栏入口改为 Helper 直开终端链路；“一键添加到 Finder”通过写 Finder toolbar 配置并重启 Finder，实现激进自动注入，失败时回落到手动拖拽提示。

**Tech Stack:** SwiftUI, AppKit, Tuist, AppleScript, UserDefaults/plist, xcodebuild, hdiutil.

---

### Task 1: 恢复 Helper 目标并嵌入主 App（单 Bundle 分发）

**Files:**
- Modify: `Project.swift`
- Create: `Apps/PathBridgeHelper/Sources/PathBridgeHelperApp.swift`
- Create: `Apps/PathBridgeHelper/Sources/PathBridgeHelperAppDelegate.swift`
- Create: `Apps/PathBridgeHelper/PathBridgeHelper.entitlements`
- Create: `Apps/PathBridgeHelper/Resources/Assets.xcassets/**`

**Step 1: 写失败验证（结构验证）**
- 运行 `tuist generate`，预期当前工程不存在 `PathBridgeHelper` scheme。

**Step 2: 最小实现**
- 新增 `PathBridgeHelper` target（`product: .app`，`LSUIElement=1`）。
- PathBridgeApp 依赖 PathBridgeHelper，并通过 post build script 将 Helper 拷贝到 `PathBridge.app/Contents/MacOS/PathBridgeHelper.app`。
- Helper 复用当前稳定终端打开链路（读取 Finder front directory + adapter open + 自动退出）。

**Step 3: 验证**
- `tuist generate`
- `xcodebuild build -scheme PathBridgeHelper`
- `xcodebuild build -scheme PathBridgeApp`
- `find build -name PathBridgeHelper.app` 检查主 App 内嵌路径存在。

**Step 4: 提交**
- `git add ...`
- `git commit -m "feat: restore embedded helper architecture for finder quick-open"`

### Task 2: 主 App 角色收敛（只做设置，不做快开）

**Files:**
- Modify: `Apps/PathBridgeApp/Sources/AppDelegate.swift`
- Modify: `Apps/PathBridgeApp/Sources/PathBridgeApp.swift`

**Step 1: 写失败验证（行为验证）**
- 现状：点击主 App 图标可能触发 quick-open，属于失败行为。

**Step 2: 最小实现**
- 删除/停用主 App quick-open 触发分支（`open urls`、`reopen` 里的终端执行逻辑）。
- 保留窗口样式修正逻辑，确保只打开设置 UI。

**Step 3: 验证**
- `xcodebuild build -scheme PathBridgeApp`
- 手动验证：Launchpad/Dock 打开仅出现设置窗口，不打开终端。

**Step 4: 提交**
- `git add ...`
- `git commit -m "refactor: make host app settings-only role"`

### Task 3: 激进“一键添加到 Finder”实现

**Files:**
- Modify: `Apps/PathBridgeApp/Sources/ViewModels/ExtensionGuideViewModel.swift`
- Modify: `Apps/PathBridgeApp/Sources/Localization/AppLocalizer.swift`
- Modify: `Apps/PathBridgeApp/Sources/ContentView.swift`
- Create: `Apps/PathBridgeApp/Sources/Services/FinderToolbarInstaller.swift`

**Step 1: 写失败验证（路径验证）**
- 现状按钮只定位 App，不会自动注入 Finder toolbar。

**Step 2: 最小实现**
- 新增 FinderToolbarInstaller：
  - 读取 `com.apple.finder` 的 `NSToolbar Configuration Browser`
  - 在 `TB Item Identifiers` 插入 `com.apple.finder.loc `
  - 在 `TB Item Plists` 写入 helper 路径对应 plist（`_CFURLString` + alias/bookmark data）
  - 写回后重启 Finder。
- 安装失败时回退：打开 Finder 定位主 App，并给出 Command 拖拽提示。

**Step 3: 验证**
- `xcodebuild build -scheme PathBridgeApp`
- 手动验证：点击“一键添加到 Finder”后 Finder 重启并出现入口；入口点击直接开终端。

**Step 4: 提交**
- `git add ...`
- `git commit -m "feat: implement aggressive finder toolbar auto-install"`

### Task 4: 兼容与回归

**Files:**
- Modify: `Extensions/PathBridgeFinderExtension/Sources/FinderSync.swift`（可选：降级为备用能力）
- Modify: `README.md`
- Modify: `docs/signing-and-dmg.md`
- Modify: `tasks/todo.md`

**Step 1: 回归检查**
- 终端选择是否生效（Terminal / iTerm2 / Warp / Kaku）。
- `newTab/newWindow` 是否生效。
- 失败提示是否 toast，不兜底系统 Terminal。

**Step 2: 构建与测试**
- `xcodebuild test -scheme PathBridgeSharedTests`
- `xcodebuild test -scheme PathBridgeTerminalAdaptersTests`
- `xcodebuild test -scheme PathBridgeAppTests`
- `xcodebuild build -scheme PathBridgeHelper`
- `xcodebuild build -scheme PathBridgeApp`

**Step 3: 提交**
- `git add ...`
- `git commit -m "docs: align architecture and verification with go2shell parity"`

### Task 5: 产出 DMG（最终交付）

**Files:**
- Modify: `scripts/release/make_dmg.sh`（如需）

**Step 1: 打包**
- `scripts/release/make_dmg.sh`

**Step 2: 验证产物**
- 校验 DMG 内仅 `PathBridgeApp.app`（Helper 内嵌在主 App 包体里）。
- 记录 `sha256`。

**Step 3: 交付说明**
- 输出 DMG 路径、哈希、安装验证步骤。
