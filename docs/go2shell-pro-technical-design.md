# go2shell Pro 技术设计（Phase 1）

## 1. 目标架构
组件：
- Finder Sync Extension：采集 Finder 上下文并发起动作请求。
- Host App（LSUIElement 菜单栏应用）：统一执行动作、展示设置与日志。
- Core 模块：路径解析、策略引擎、错误分类。
- TerminalAdapters 模块：各终端适配与能力探测。

通信建议：
- 首选 App Group + XPC（请求/响应），保证扩展与主应用解耦。
- 兜底：主应用不可达时，扩展执行最小可用动作（仅 open 目录）。

## 2. 关键协议设计

### 2.1 TerminalAdapter 协议
```swift
protocol TerminalAdapter {
    var id: String { get }                    // 唯一标识，如 "com.iterm2"
    var displayName: String { get }           // 显示名称，如 "iTerm2"
    var bundleIdentifier: String? { get }     // Bundle ID，用于检测安装状态

    func isInstalled() -> Bool                // 检测终端是否已安装
    func capabilities() -> TerminalCapabilities
    func open(paths: [URL], mode: OpenMode, command: String?) -> ExecutionResult
}
```

### 2.2 OpenMode 枚举
```swift
enum OpenMode {
    case newWindow      // 新窗口
    case newTab         // 新标签页
    case reuseCurrent   // 复用当前窗口
}
```

### 2.3 ExecutionResult 结果
```swift
enum ExecutionResult {
    case success(latencyMs: Int)
    case failed(error: ExecutionError)
}

enum ExecutionError: Error {
    case terminalNotInstalled
    case timeout(ms: Int)
    case permissionDenied
    case pathNotAccessible(String)
    case commandExecutionFailed(String)
    case unknown(String)
}
```

### 2.4 CommandTemplate 命令模板
```swift
struct CommandTemplate {
    var rawTemplate: String          // 原始模板字符串
    var resolvedCommand: String      // 占位符解析后的命令

    static let `default` = "cd %PATH_QUOTED%; clear; pwd"

    /// 支持的占位符
    enum Placeholder: String, CaseIterable {
        case path = "%PATH%"
        case pathQuoted = "%PATH_QUOTED%"
        case dirname = "%DIRNAME%"
        case user = "%USER%"
        case home = "%HOME%"
    }

    /// 风险提示关键字（仅提示，不作为安全边界）
    static let dangerousPatterns = [
        "rm -rf",
        "sudo ",
        "mkfs",
        "dd if=",
        ":(){ :|:& };:",
        "> /dev/sd"
    ]

    /// 解析占位符
    mutating func resolve(with context: PathContext) -> String

    /// 检测是否包含危险命令
    func containsDangerousCommand() -> Bool
}

struct PathContext {
    let path: URL
    var pathString: String { path.path }
    var pathQuoted: String { "\"\(path.path)\"" }
    var dirname: String { path.lastPathComponent }
    var user: String { NSUserName() }
    var home: String { NSHomeDirectory() }
}
```

### 2.5 TerminalCapabilities 能力描述
```swift
struct TerminalCapabilities {
    let supportsNewWindow: Bool
    let supportsNewTab: Bool
    let supportsReuseCurrent: Bool
    let supportsCommand: Bool           // 是否支持启动后执行命令
    let preferredMethod: AdapterMethod  // 首选调用方式
}

enum AdapterMethod {
    case cli(String)         // CLI 命令，如 "wezterm start --cwd"
    case urlScheme(String)   // URL Scheme，如 "warp://"
    case appleScript         // AppleScript
    case openCommand         // open -a
}
```

### 2.6 TerminalAdapterRegistry 适配器注册
```swift
class TerminalAdapterRegistry {
    static let shared = TerminalAdapterRegistry()

    private(set) var adapters: [TerminalAdapter] = []

    /// 注册适配器
    func register(_ adapter: TerminalAdapter)

    /// 获取所有已安装的终端
    func installedAdapters() -> [TerminalAdapter]

    /// 获取默认终端（偏好设置或系统 Terminal）
    func defaultAdapter() -> TerminalAdapter

    /// 刷新安装状态缓存
    func refreshCache()
}
```

默认策略：
- 跨目录多选默认 `newWindow`。
- 同目录多选默认聚合单次打开。

## 3. 终端适配策略（按可靠性分层）
- Layer A：官方 CLI（优先，最稳定）。
- Layer B：URL Scheme。
- Layer C：`open -a <App> <path>`（通用回退）。
- Layer D：AppleScript（仅在必须控制 tab/window 语义时使用）。

安装检测策略：
- 优先按 Bundle ID 检测；
- 对多发行渠道终端（如 Stable/Nightly）支持 Bundle ID 候选列表；
- Bundle ID 未命中时回退应用名检测（`open -Ra "<AppName>"` 试探）；
- 最终统一回退系统 Terminal，保证“必可用”。

Kaku 方案：
- 优先尝试 `kaku cli spawn --new-window --cwd <path>`。
- 若 CLI 不可用或执行失败，回退 `open -a Kaku <path>`。
- 注意：`kaku cli` 在上游标记为 hidden/experimental，需能力探测与降级。

## 4. 路径与安全
路径处理：
- 统一标准化：`resolvingSymlinksInPath` + 去重 + 可访问性校验。
- 记录原始输入与标准化结果，便于诊断。

权限与安全：
- 不采集云端遥测；日志仅本地。
- 命令模板默认关闭，启用时展示风险提示（Shell 注入边界）。
- 命令执行前生成“最终命令预览”，用于诊断与审计。

### 4.1 命令执行安全策略（必做）
- 不将 Finder 原始路径直接拼接到 shell；统一使用占位符替换后再执行。
- 路径默认使用 `%PATH_QUOTED%`，避免空格和特殊字符导致执行偏差。
- 多选模式下默认逐路径独立执行，禁止把多个路径拼成一条未转义命令。
- `dangerousPatterns` 只做风险提示与二次确认，不能替代安全控制。

## 5. 并发与稳定性
- 动作执行采用串行队列（避免多次点击导致窗口风暴）。
- 同一目录 500ms 去抖合并。
- 超时控制：单次适配执行默认 3s，超时即降级。

## 6. 测试与验证矩阵
自动化测试：
- Core 单元测试：路径解析、策略决策、错误映射。
- Adapter 合约测试：installed / not-installed / timeout / fallback。

手工回归矩阵（最小）：
- macOS 14/15（Intel + Apple Silicon）。
- Finder 场景：单目录、单文件、多选同目录、多选跨目录、网络卷。
- 终端场景：Terminal、iTerm2、Warp、Kaku 至少 4 个实机通过。

## 7. 发布流水线（DMG）
发布启动门禁（必须同时满足）：
1. 功能冻结（Feature Complete）。
2. 联调通过（Finder 扩展 + 主应用 + 终端适配器）。
3. 自测/回归通过（关键场景无阻塞问题）。

当前阶段策略：
- 先完成功能实现与联调自测，不立即执行签名/公证发布步骤。
- 发布门禁达成后再执行以下流水线。

CI 阶段：
1. `tuist install && tuist generate`
2. `xcodebuild archive`
3. 导出 `.app`、生成 `.zip`、生成 `.dmg`
4. Developer ID 签名与 notarization
5. notarization stapling + Gatekeeper 验证
6. 上传 GitHub Release（含 SHA256）

验收命令（发布前）：
- `codesign --verify --deep --strict --verbose=2 <App.app>`
- `spctl --assess --type execute --verbose <App.app>`
- `xcrun stapler validate <App.app>`
