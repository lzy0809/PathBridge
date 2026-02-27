# go2shell Pro 技术设计（Phase 1 / V2）

## 1. 目标架构
组件：
- Finder Sync Extension：采集 Finder 上下文并发起请求。
- Host App（LSUIElement 菜单栏应用）：执行动作、持久化设置、展示设置与日志。
- Core：路径解析、命令模板解析、错误分类。
- TerminalAdapters：终端能力探测与执行。
- Shared：请求/配置模型与通信协议。

通信策略：
- Phase 1：沿用 App Group + DistributedNotification（当前已通）。
- Phase 1.5：升级为 App Group + XPC（替换通知通道）。
- 兜底：主应用不可达时扩展直接执行系统 Terminal 最小动作。

## 2. 平台约束与入口策略
- Finder Sync API 下，工具栏按钮点击会触发系统展示扩展菜单，不支持“无菜单直开”。
- 实际落地：
  - 右键菜单提供 `Open in <Default Terminal>` 作为主路径。
  - 工具栏菜单第一项提供 `Quick Open in <Default Terminal>`。

## 3. 核心协议设计

### 3.1 OpenRequest
```swift
struct OpenRequest: Codable, Sendable {
    let paths: [String]
    let terminalID: String
    let mode: OpenMode
    let commandTemplate: String?
}
```

### 3.2 TerminalAdapter
```swift
protocol TerminalAdapter {
    var id: String { get }
    var displayName: String { get }
    var bundleIdentifier: String? { get }

    func isInstalled() -> Bool
    func open(paths: [URL], mode: OpenMode, command: String?) throws
}
```

### 3.3 AppSettings（新增）
```swift
struct AppSettings: Codable {
    var defaultTerminalID: String
    var defaultOpenMode: OpenMode
    var defaultCommandTemplate: String
    var activateAfterOpen: Bool
    var debugMode: Bool
}
```

默认值：
- `defaultTerminalID = system-terminal`
- `defaultOpenMode = .newWindow`
- `defaultCommandTemplate = "cd %PATH_QUOTED%; clear; pwd"`
- `activateAfterOpen = true`
- `debugMode = false`

## 4. 终端适配策略（Phase 1 冻结）
首发支持：
- Terminal（P0）
- iTerm2（P0）
- Warp（P0）

回退链路：
1. 目标终端执行失败。
2. 若允许回退则改用系统 Terminal。
3. 仍失败则返回明确错误文案。

## 5. 路径与命令安全
路径处理：
- `SelectionResolver.normalize`：文件转父目录、符号链接解析、去重。

命令模板：
- 占位符替换由 `CommandTemplateResolver` 完成。
- 默认使用 `%PATH_QUOTED%`。
- 风险关键字仅用于提示，不作为安全边界。

## 6. UI 与状态管理
ViewModel 拆分：
- `SettingsViewModel`：默认终端、打开模式、命令模板。
- `ExtensionGuideViewModel`：扩展状态与引导动作。
- `SupportViewModel`：二维码资源加载与预览状态。

UI 主区块：
- General
- Command Template
- Finder Extension
- Quick Actions
- Support

## 7. 错误处理与日志
错误分级：
- `terminalNotInstalled`
- `pathNotAccessible`
- `permissionDenied`
- `communicationFailed`
- `fallbackFailed`

日志策略：
- 本地最近 100 条，记录请求参数摘要、执行终端、耗时、结果。
- 不上传云端。

## 8. 测试与验证矩阵
自动化：
- Core：路径归一化、模板解析、默认值回退。
- Adapters：installed/not-installed/timeout/fallback。
- Settings：读写持久化和迁移。

手工回归：
- macOS 14/15。
- Finder：单选目录、单选文件、多选同目录、多选跨目录。
- UI：默认终端切换、模板修改、扩展引导、Test Open、支持区展示。

## 9. 发布策略（维持）
- 不上架 App Store。
- Phase 1：DMG + Developer ID + notarization。
- Phase 2：Homebrew Cask（后置）。
