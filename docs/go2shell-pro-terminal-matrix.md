# go2shell Pro 终端兼容矩阵（Phase 1）

## 1. 终端适配详情

| 终端 | Bundle ID | 检测方式 | 首选打开方式 | 回退方式 | 首发优先级 |
|---|---|---|---|---|---|
| Terminal | `com.apple.Terminal` | 系统自带，始终可用 | AppleScript 语义控制 | `open -a Terminal <path>` | P0 |
| iTerm2 | `com.googlecode.iterm2` | Bundle ID 检测 | AppleScript（新标签/窗口） | `open -a iTerm <path>` | P0 |
| Warp | `dev.warp.Warp-Stable` | Bundle ID 检测 | `warp://` URL Scheme | `open -a Warp <path>` | P0 |
| Kaku | `fun.tw93.kaku` | `which kaku` + Bundle ID | `kaku cli spawn --new-window --cwd` | `open -a Kaku <path>`（可选补充：`kaku://`） | P1 |
| WezTerm | `com.github.wez.wezterm2` | `which wezterm` + Bundle ID | `wezterm start --cwd <path>` | `open -a WezTerm <path>` | P1 |
| Ghostty | `com.mitchellh.ghostty` | Bundle ID 检测 | `ghostty://` URL Scheme | `open -a Ghostty <path>` | P1 |

## 2. 动态菜单规则

**菜单生成逻辑：**
1. Finder 菜单展开时，调用 `TerminalAdapterRegistry.installedAdapters()` 获取已安装终端
2. 仅已安装的终端出现在 `Open in...` 子菜单中
3. 未安装终端完全隐藏（不灰显）
4. 检测结果缓存 30 秒，避免频繁 IO

**检测实现：**
```swift
func isInstalled() -> Bool {
    // 方式 1：Bundle ID 检测（推荐）
    if let bundleId = bundleIdentifier {
        let workspace = NSWorkspace.shared
        if let url = workspace.urlForApplication(withBundleIdentifier: bundleId) {
            return true
        }
    }

    // 方式 2：CLI 检测（适用于有 CLI 的终端）
    if let cliPath = cliCommand {
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = [cliPath]
        // ... 执行检测
    }

    return false
}
```

**最低保障：**
- macOS 自带 Terminal 始终返回 `isInstalled() == true`
- 若用户卸载所有第三方终端，菜单仍至少显示 Terminal

## 3. 说明

- **P0**：v0.1.0 必须实机通过（Terminal、iTerm2、Warp）
- **P1**：v0.1.0 尽量支持，至少保证回退可用（Kaku、WezTerm、Ghostty）
- 第三方终端可能存在多发行渠道（Stable/Nightly）导致 Bundle ID 不同，检测逻辑需支持：
  - 主 Bundle ID 列表匹配；
  - 按应用名兜底（`open -a "<AppName>"`）；
  - 失败后统一回退系统 Terminal。
