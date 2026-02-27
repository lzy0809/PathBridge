# Finder 直达与 UI 重构 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Phase 1 范围内实现“右键单击直开默认终端 + 工具栏最小菜单 + 可配置默认终端/默认参数 + Finder 启用引导 + 感谢支持二维码”。

**Architecture:** 保持 Extension -> Host App 请求链路，扩展侧负责入口和兜底，主应用负责配置持久化与终端执行。UI 采用模块化 ViewModel 拆分，避免单页大类。Finder 入口遵守平台限制：工具栏菜单最小化，右键路径一键执行。

**Tech Stack:** Swift 6, SwiftUI, FinderSync, Tuist, DistributedNotificationCenter, XCTest。

---

### Task 1: 建立测试基线与设置模型

**Files:**
- Modify: `Project.swift`
- Create: `Packages/Shared/Sources/AppSettings.swift`
- Create: `Packages/Shared/Sources/AppSettingsStore.swift`
- Create: `Packages/Shared/Tests/AppSettingsStoreTests.swift`

**Step 1: 写失败测试（默认值与持久化）**

```swift
func test_defaultSettings_areReturnedWhenNoSavedValue()
func test_saveAndLoad_roundTripsSettings()
```

**Step 2: 运行测试确认失败**

Run: `tuist test PathBridgeSharedTests`
Expected: FAIL，提示 `AppSettingsStore` 未定义。

**Step 3: 最小实现设置模型与存储**

```swift
public struct AppSettings: Codable {
    public var defaultTerminalID: String
    public var defaultOpenMode: OpenMode
    public var defaultCommandTemplate: String
    public var activateAfterOpen: Bool
    public var debugMode: Bool
}
```

```swift
public final class AppSettingsStore {
    public func load() -> AppSettings
    public func save(_ settings: AppSettings)
}
```

**Step 4: 运行测试确认通过**

Run: `tuist test PathBridgeSharedTests`
Expected: PASS。

**Step 5: 提交**

```bash
git add Project.swift Packages/Shared/Sources/AppSettings.swift Packages/Shared/Sources/AppSettingsStore.swift Packages/Shared/Tests/AppSettingsStoreTests.swift
git commit -m "feat: add app settings model and store"
```

### Task 2: 终端适配器收敛到 Phase 1 三终端

**Files:**
- Modify: `Packages/TerminalAdapters/Sources/TerminalAdapter.swift`
- Modify: `Packages/TerminalAdapters/Sources/TerminalAdapterRegistry.swift`
- Create: `Packages/TerminalAdapters/Sources/SystemTerminalAdapter.swift`
- Create: `Packages/TerminalAdapters/Sources/ITerm2Adapter.swift`
- Create: `Packages/TerminalAdapters/Sources/WarpAdapter.swift`
- Create: `Packages/TerminalAdapters/Tests/TerminalAdapterRegistryTests.swift`

**Step 1: 写失败测试（安装探测与默认回退）**

```swift
func test_registryReturnsInstalledAdaptersOnly()
func test_defaultAdapterFallsBackToSystemTerminal()
```

**Step 2: 运行测试确认失败**

Run: `tuist test PathBridgeTerminalAdaptersTests`
Expected: FAIL，提示缺少适配器实现。

**Step 3: 最小实现三个适配器 + 注册表策略**

```swift
public func defaultAdapter(preferredID: String?) -> any TerminalAdapter
```

规则：优先用户设置，找不到则回退 `system-terminal`。

**Step 4: 运行测试确认通过**

Run: `tuist test PathBridgeTerminalAdaptersTests`
Expected: PASS。

**Step 5: 提交**

```bash
git add Packages/TerminalAdapters/Sources Packages/TerminalAdapters/Tests Project.swift
git commit -m "feat: add phase1 terminal adapters and registry fallback"
```

### Task 3: Finder 入口改造（右键直开 + 工具栏最小菜单）

**Files:**
- Modify: `Extensions/PathBridgeFinderExtension/Sources/FinderSync.swift`
- Create: `Packages/Core/Tests/SelectionResolverTests.swift`

**Step 1: 写失败测试（选择归一化）**

```swift
func test_fileSelection_resolvesToParentDirectory()
func test_duplicateSelection_isDeduplicatedAfterSymlinkResolution()
```

**Step 2: 运行测试确认失败**

Run: `tuist test PathBridgeCoreTests`
Expected: FAIL，当前行为或测试目标缺失。

**Step 3: 实现 Finder 菜单策略**

- 右键菜单：只放 `Open in <Default Terminal>` 并直开。
- 工具栏菜单：`Quick Open in <Default Terminal>` + `Open in...` + `Preferences...`。
- Host 不可达时维持系统 Terminal 兜底。

**Step 4: 运行测试确认通过**

Run: `tuist test PathBridgeCoreTests`
Expected: PASS。

**Step 5: 提交**

```bash
git add Extensions/PathBridgeFinderExtension/Sources/FinderSync.swift Packages/Core/Tests/SelectionResolverTests.swift Project.swift
git commit -m "feat: implement finder quick-open menu strategy"
```

### Task 4: 主应用 UI 重构（功能对标）

**Files:**
- Modify: `Apps/PathBridgeApp/Sources/ContentView.swift`
- Create: `Apps/PathBridgeApp/Sources/ViewModels/SettingsViewModel.swift`
- Create: `Apps/PathBridgeApp/Sources/ViewModels/ExtensionGuideViewModel.swift`
- Create: `Apps/PathBridgeApp/Sources/ViewModels/SupportViewModel.swift`
- Modify: `Apps/PathBridgeApp/Sources/AppDelegate.swift`

**Step 1: 写失败测试（ViewModel 默认值与动作）**

```swift
func test_settingsViewModel_loadsDefaults()
func test_extensionGuide_generatesSystemSettingsURL()
```

**Step 2: 运行测试确认失败**

Run: `tuist test PathBridgeAppTests`
Expected: FAIL，测试 target 或 ViewModel 未实现。

**Step 3: 最小实现 UI 区块**

- General: 默认终端、打开模式、激活前台。
- Command Template: 模板编辑 + 恢复默认。
- Finder Extension: 打开系统设置按钮 + 状态文本。
- Quick Actions: Test Open。

**Step 4: 运行测试确认通过**

Run: `tuist test PathBridgeAppTests`
Expected: PASS。

**Step 5: 提交**

```bash
git add Apps/PathBridgeApp/Sources Project.swift
git commit -m "feat: redesign settings ui with finder guide and quick actions"
```

### Task 5: 感谢支持区与资源接入

**Files:**
- Create: `Apps/PathBridgeApp/Resources/Support/README.md`
- Create: `Apps/PathBridgeApp/Resources/Support/donation-qr-1.png`（占位图）
- Create: `Apps/PathBridgeApp/Resources/Support/donation-qr-2.png`（占位图）
- Modify: `Apps/PathBridgeApp/Sources/ContentView.swift`

**Step 1: 写失败测试（资源存在性）**

```swift
func test_supportResources_existInBundle()
```

**Step 2: 运行测试确认失败**

Run: `tuist test PathBridgeAppTests`
Expected: FAIL，提示资源缺失。

**Step 3: 最小实现支持区**

- UI 展示两张二维码缩略图。
- 点击后弹出预览。
- 所有资源本地打包，无网络请求。

**Step 4: 运行测试确认通过**

Run: `tuist test PathBridgeAppTests`
Expected: PASS。

**Step 5: 提交**

```bash
git add Apps/PathBridgeApp/Resources/Support Apps/PathBridgeApp/Sources/ContentView.swift
git commit -m "feat: add support donation section with local qr assets"
```

### Task 6: 端到端验证与文档回写

**Files:**
- Modify: `tasks/todo.md`
- Modify: `docs/go2shell-pro-interaction-spec.md`
- Modify: `docs/go2shell-pro-technical-design.md`

**Step 1: 执行构建与测试**

Run:
```bash
tuist install && tuist generate
tuist test
xcodebuild -workspace PathBridge.xcworkspace -scheme PathBridgeApp -configuration Debug build
```

Expected: 全部通过。

**Step 2: 手工联调清单**

Run / Check:
```bash
pluginkit -m -p com.apple.FinderSync | rg pathbridge
```

Expected: 扩展可见；在 Finder 执行右键直开和工具栏 Quick Open 均成功。

**Step 3: 更新任务追踪与回顾**

- 勾选 `tasks/todo.md` 对应项。
- 写入本轮结果与风险。

**Step 4: 提交**

```bash
git add tasks/todo.md docs/go2shell-pro-interaction-spec.md docs/go2shell-pro-technical-design.md
git commit -m "docs: finalize finder direct-open and ui redesign plan"
```
