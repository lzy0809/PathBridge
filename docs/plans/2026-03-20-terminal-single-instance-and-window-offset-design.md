# PathBridge 单实例终端复用与窗口偏移设计

## 背景

用户反馈当前通过 Finder 工具栏打开 Kaku / iTerm2 时，Dock 会出现多个终端运行图标；再次打开新窗口时，新窗口位置与已有窗口重叠，用户难以感知“已经成功新开”；同时 PathBridge 主窗口点击左上角关闭后仍不退出。

对 `/Applications/Go2Shell.app` 的本地取证表明：

- Go2Shell 采用“主 App + `LSUIElement` Helper”结构。
- 主/辅二进制中存在 `openAppleTerminalWithCommand:inNewWindow:`、`openiTermWithCommand:inNewWindow:`、`openiTerm2NextGenerationWithCommand:inNewWindow:` 等专用终端入口。
- 二进制中直接包含 AppleScript / `System Events` 的新标签命令，说明其核心不是 `open -n`，而是“控制已有终端实例开新窗口/标签”。

## 根因

1. iTerm2 当前仍走 `OpenCommandLauncher`，`newWindow` 模式会附带 `open -n`，这会显式创建新 app 实例，Dock 多图标属于必然结果。
2. Kaku 当前仍以启动内部可执行文件为主，虽然已去掉 `--always-new-process`，但仍未优先利用现有 GUI 实例做“同实例新窗口”。
3. PathBridge 没有“最后一个窗口关闭即退出”的应用级策略。
4. 窗口偏移缺少统一控制层；iTerm2 有脚本 `bounds` 能力，Kaku 无公开脚本字典，需要通过辅助功能接口移动窗口。

## 方案

### 1. iTerm2

- 不再使用 `open -n` / `open -a iTerm` 作为主路径。
- `newWindow`：使用 AppleScript `create window with default profile` 或等价脚本命令创建同实例新窗口。
- `newTab`：使用 AppleScript `create tab with default profile`。
- 新窗口创建成功后读取前一个窗口 `bounds`，对新窗口做固定偏移，例如 `(+28, +28)`。
- 创建后显式 `activate`，确保新窗口前置。

### 2. Kaku

- 运行中优先：`kaku cli spawn --new-window --cwd <path>`，目标是复用现有 GUI 实例。
- 未运行时回退：`kaku-gui start --cwd <path>`。
- 若需要新标签则继续使用 `kaku-gui start --new-tab --cwd <path>` 或 `cli spawn`。
- 新窗口偏移：
  - 当走 `start` 且无运行实例时，可直接利用 `--position`。
  - 当走 `cli spawn` 复用实例时，创建后通过辅助功能接口定位新前台 Kaku 窗口，并相对上一窗口偏移。
- 失败时保留现有日志与错误回退。

### 3. 公共窗口偏移控制

- 新增一个轻量 `WindowOffsetController` / `AccessibilityWindowController`。
- 记录最近一次窗口位置快照，默认偏移量固定。
- iTerm2 使用脚本接口直接设 `bounds`。
- Kaku 使用 `AXUIElement` 获取目标应用窗口并移动。
- 若未授予辅助功能权限：
  - 首次尝试时触发系统提示。
  - 同时返回可读错误/日志，但不阻断终端打开。

### 4. PathBridge 关窗退出

- 在主 App delegate 中实现 `applicationShouldTerminateAfterLastWindowClosed` 返回 `true`。
- 保持 Finder 工具栏快开路径不受影响。

## 测试

- 终端适配器测试：
  - iTerm2 新窗口/新标签脚本内容。
  - iTerm2 不再走 `open -n`。
  - Kaku 在“已有运行实例”时优先 `cli spawn --new-window`。
  - Kaku 首次启动时能生成包含 `--position` 的参数。
  - 窗口偏移计算结果正确。
- App 测试：
  - `applicationShouldTerminateAfterLastWindowClosed` 为 `true`。

## 风险与处理

- Kaku 辅助功能移动窗口依赖系统授权。处理方式是“打开不阻断，偏移尽力完成，并给出权限引导”。
- AppleScript/辅助功能在不同系统版本上可能存在差异，因此优先保持“单实例复用”正确，其次再追求偏移体验。
