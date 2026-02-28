# Todo

## 当前任务（2026-02-28，开源发布与维护性收敛）
- [x] 清理冗余代码与过时链路（未使用字段、未使用模块、历史兼容残留），降低维护成本。
- [x] 收敛 Xcode scheme，仅保留对外开发必需方案，避免 target 级 scheme 噪音。
- [x] 设计并替换完全自有 icon（App + Launcher 统一），去除对第三方视觉资产依赖。
- [x] 完成 GitHub 开源发布准备（README/发布说明/许可证/安全检查），并评估自动化发布路径。
- [x] 规划并落地 Homebrew Cask/tap 方案（tap 仓库名：`lzy9527/homebrew-tap`）。

## 当前任务（2026-02-28，Go2Shell 100% 对标重构规划）
- [x] 基于本机 `/Applications/Go2Shell.app` 做结构取证（主 App + 内嵌 LSUIElement Helper）。
- [x] 对比当前 PathBridge 架构差异（当前为 Host App + FinderSync Extension）。
- [x] 输出“Go2Shell 式激进实现”设计文档并冻结目标行为。
- [x] 按设计进入实施：恢复双角色（设置 App + 无 Dock Helper）并保证外部分发仍为单 `.app`。
- [x] 实现激进“一键添加到 Finder”路径（写 Finder toolbar 配置 + 重启 Finder）并保留手动拖拽兜底。
- [x] 回归验证：Finder 工具栏点击直开终端、不弹菜单、不弹设置窗口、Dock 不常驻。
- [x] 修复单 App 内嵌 Helper 后的签名封包错误（ad-hoc 重新签名），并生成可安装 DMG：`build/release/dmg/PathBridge-20260228-101100-82dd1a2.dmg`。
- [x] 修复 Finder 工具栏图标不一致：同步 App/Launcher `AppIcon` 资源并更新图标生成脚本同时覆盖两端。
- [x] 修复 macOS 26 Kaku 打开失败：适配器改为多执行文件+多策略尝试（`kaku`/`kaku-gui` + `start/cli spawn`）并补充日志与测试。
- [x] 重新打包验证：`build/release/dmg/PathBridge-20260228-112227-82dd1a2.dmg`（SHA256 已生成）。

## 当前任务（2026-02-27，入口行为分流与无界面快开）
- [x] 设置页标题与副标题改为水平居中。
- [x] 普通启动（Launchpad/Dock）仅打开设置界面，不触发快开终端。
- [x] Finder 工具栏启动走无界面快开终端，执行后自动退出，避免 Dock 常驻与运行指示。
- [x] 回归验证并重新打包无签名 DMG 供用户复测。

## 当前任务（2026-02-27，Finder 自动化授权拦截修复）
- [x] 为主 App 补充 `NSAppleEventsUsageDescription`，确保 Finder 自动化可触发系统授权弹窗。
- [x] 捕获 Finder Apple Events 拒绝（`-1743`）并给出清晰用户引导（通知 + 打开系统设置自动化页）。
- [x] 回归验证（App 测试 + FinderExtension 构建）并重新生成无签名 DMG 给用户验证。

## 当前任务（2026-02-27，Finder 点击无响应 + 语言入口可见性）
- [x] 修复单 Bundle 下 Finder 工具栏图标点击无响应（补齐 `reopen` quick-open 打开链路）。
- [x] 保持 Finder 扩展 deep-link 直达能力，避免回归。
- [x] 将语言切换入口下移到稳定可见区域，避免顶部裁切导致入口消失。
- [x] 调整窗口顶部/高度，修复标题与内容被遮挡问题。
- [x] 运行构建与测试回归，并生成新的无签名 DMG 供实机验证。

## 当前任务（2026-02-27，单 Bundle 架构收敛）
- [x] 移除 `PathBridgeLauncher` 目标，统一为单可执行 `PathBridgeApp`。
- [x] Finder 扩展回退链路改为直接唤起 `PathBridgeApp`（不再依赖 Launcher）。
- [x] 更新安装提示文案与“添加到 Finder”定位逻辑，改为 `PathBridgeApp`。
- [x] 更新打包脚本与文档，DMG 仅包含 `PathBridgeApp.app`。
- [x] 运行构建/测试回归并重新生成无签名 DMG。

## 当前任务（2026-02-27，单 Bundle 回归修复）
- [x] 修复单 Bundle 下 Finder 点击无响应（补齐 App 启动/重开快开逻辑）。
- [x] 修复设置窗口上下遮挡（调整标题区布局、窗口尺寸与安全区处理）。
- [x] 回归验证并重新生成可测试 DMG。

## 当前任务（2026-02-27，临时无签名 DMG 验证）
- [x] 运行无签名打包脚本，生成可安装 `dmg`（含 Launcher）。
- [x] 输出产物路径与 `sha256`，供特定机型安装验证。

## 当前任务（2026-02-27，Tahoe 适配与轻量图标）
- [x] 优化主窗口顶部安全区与标题布局，修复 Tahoe 26 可能出现的顶部遮挡。
- [x] 缩小并轻量化 App/Launcher 图标，降低 Finder 工具栏视觉权重并保持主题统一。
- [x] 微调支持按钮与语言入口间距，保持紧凑布局下的可读性与对齐。
- [x] 回归验证 `PathBridgeApp` 测试与 `PathBridgeLauncher` 构建。

## 当前任务（2026-02-27，签名与 DMG 打包）
- [x] 新增本地发布脚本：archive -> app 校验 -> DMG 打包 -> 可选签名/公证。
- [x] 新增签名与公证说明文档（证书、notary profile、环境变量）。
- [x] 运行一次“无签名”本地打包验证，确保可产出可安装 DMG。
- [x] 回答并固化 Finder 一键安装边界说明（是否仍需手动拖拽）。

## 当前任务（2026-02-27，UI提示与图标迭代）
- [x] 缩小安装提示区字号，避免挤压主窗口导致底部按钮不可见。
- [x] 提示文案去路径化，改为固定短文案与状态提示。
- [x] 重绘一版统一主题 icon（App + Launcher 同步）。
- [x] 回归验证 `PathBridgeApp` 测试与 `PathBridgeLauncher` 构建。

## 当前任务（2026-02-27，提交前收尾）
- [x] 放大并强化橘色提示文案，提升可读性与醒目程度。
- [x] 修复 Kaku 新 tab/new window 参数映射，避免目录打开不稳定。
- [x] 扩展终端适配器并在设置页展示全部支持项（未安装明确标注）。
- [x] 去除“失败时兜底系统 Terminal”行为，改为 toast 提示“暂不支持”。
- [x] 重做并统一 App/Launcher 图标（基于 Kaku 风格）。
- [x] 运行全量回归（Shared/TerminalAdapters/App 测试 + Launcher/FinderExtension 构建）。

## 当前任务（2026-02-27，Kaku 目录修复与紧凑UI）
- [x] 修复 Kaku 打开目录：改为调用 Kaku CLI `cli spawn --cwd`，确保进入选中目录。
- [x] 增加 Kaku 启动参数测试（`newWindow/newTab` 映射到正确 CLI 参数）。
- [x] 将设置窗口改为紧凑布局（尺寸、控件密度、信息层级）并向 Go2Shell 风格靠拢。
- [x] 构建与测试回归，给出用户侧验证步骤。

## 当前任务（2026-02-27，终端链路日志增强）
- [x] 建立请求级追踪：为 Finder 请求增加 `requestID` 并贯穿 Host/Launcher/Adapter 日志。
- [x] 在设置读取与终端路由关键决策点打日志（读取来源、默认终端、打开模式、回落原因）。
- [x] 在 `open` 执行层记录实际启动参数与失败 stderr。
- [x] 提供可复现场景的日志抓取命令，并完成构建/测试回归。

## 当前任务（2026-02-27，终端选择与打开模式修复）
- [x] 复现并定位“无论选择哪个终端都回落系统 Terminal”的真实触发链路（Launcher / Finder 扩展 / Host App）。
- [x] 补充失败测试：覆盖默认打开模式解析（`reuseCurrent` 应回退到用户设置）与终端适配器优先策略。
- [x] 修复 Finder 扩展请求模式传递（不再硬编码 `newWindow`，改为“跟随默认设置”）。
- [x] 修复终端适配器选择策略（优先尝试用户选择的适配器，失败后再回落系统 Terminal）。
- [x] 回归验证 `PathBridgeShared` / `PathBridgeTerminalAdapters` / `PathBridgeApp` 测试并记录结论。

## 当前任务（2026-02-27，需求/规划审阅与重构）
- [x] 回顾 `tasks/lessons.md`，确认本轮规划约束（终端矩阵、默认交互、发布门禁）。
- [x] 审阅现有产品/交互/技术文档与当前代码，定位与新诉求冲突项。
- [x] 澄清目标细节（Finder 一步直达行为、UI 对标 go2shell 的范围与优先级）。
- [x] 输出 2-3 个可行方案并给出推荐（含技术可行性与风险）。
- [x] 形成修订后设计并征求确认。
- [x] 将确认后的设计写入 `docs/plans/2026-02-27-finder-direct-open-and-ui-redesign-design.md`。
- [x] 基于设计生成实施计划并同步回 `tasks/todo.md`。
- [x] 验证实施计划可执行性（核对当前项目结构、测试目标与落地顺序）。

## 当前任务（2026-02-27）
- [x] 拉取并审阅 `https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md`。
- [x] 按文档在本仓库执行安装/配置步骤。
- [x] 验证安装结果（命令输出/文件变更）并记录回顾。

## 规划阶段
- [x] 明确目标：做 go2shell 高级版，核心保持 Finder 打开终端。
- [x] 调研参考项目：分析 MoePeek 的 Tuist/Release/DMG 流程。
- [x] 决定阶段划分：Phase 1 先做 DMG，Phase 2 再做 Homebrew。
- [x] 输出产品与实现规划文档：`docs/go2shell-pro-plan.md`。
- [x] 新增终端支持：纳入 Kaku（并规划 CLI 优先、App 打开回退策略）。
- [x] 细化交互规格：`docs/go2shell-pro-interaction-spec.md`。
- [x] 细化技术设计：`docs/go2shell-pro-technical-design.md`。
- [x] 输出终端兼容矩阵：`docs/go2shell-pro-terminal-matrix.md`。
- [x] 确认终端支持优先级（Terminal/iTerm2/Warp/WezTerm/Ghostty/Kaku）。
- [x] 确认 Finder 交互形态优先级（工具栏优先，右键次优先，服务菜单可选）。
- [x] 确认首发范围：P0 终端（Terminal/iTerm2/Warp）与 P1 终端（Kaku/WezTerm/Ghostty）。
- [x] 确认签名策略：对外发布必须 Developer ID + notarization，但发布流程后置到联调/自测通过后。
- [x] 补充发布门禁检查清单（联调通过、自测通过、回归通过、签名公证通过）：`docs/release-gate-checklist.md`。
- [ ] 实机确认第三方终端多发行渠道信息（Bundle ID / URL Scheme 候选列表）。
- [ ] 补充 Finder 扩展权限引导在 macOS 14/15 的差异化文案与截图。

## 实施阶段（进行中）
- [x] 在 `go2/` 下初始化独立 Git 仓库（避免误用上层仓库）。
- [x] 关联远程仓库：`https://gitee.com/liangzhiyuan/path-bridge.git`。
- [x] 统一主分支为 `main`。
- [x] 初始化 Tuist 工程骨架（App + Finder Extension + Core + Shared + TerminalAdapters）。
- [x] 安装 Tuist 并生成本地工程（`tuist install && tuist generate`）。
- [x] 实现最小可用链路：工具栏菜单点击 -> 打开系统 Terminal。
- [x] 打通 Finder Extension 到 Host App 的请求通道（已实现 DistributedNotification 通道）。
- [x] 补齐 App/Extension entitlements（App Sandbox + Finder 基础权限）。
- [x] 增加 Finder 扩展入口排查文档（签名、pluginkit 注册、Finder 重启）。
- [x] 修复 Support 二维码资源定位（改为从 App Resources 根目录加载），并补齐 `PathBridgeApp` 资源测试。
- [x] 梳理 Finder 真机联调入口不可见问题（scheme 选择、扩展启用、工具栏展示路径）并补充操作指引。
- [x] 重构 `PathBridgeApp` 设置页为现代化视觉风格（强化层次、交互反馈、信息密度），保持功能对标不变。
- [x] 完成 UI 改造后的四个 scheme 回归测试，并记录结果。
- [x] 按用户反馈回滚 UI 到上一版稳定布局（保留原有功能结构）。
- [x] Finder 扩展工具栏点击改为“直开默认终端”（移除工具栏弹出菜单）。
- [x] 修复 App 内“重启 Finder”失败（从 `killall` 改为 Apple Events + `NSWorkspace` 拉起 Finder）。
- [x] 修复二维码图片解码 CRC 报错（替换为可正常解码的 PNG 占位图并验证日志）。
- [x] 联网调研 go2shell/openinterminal 实现方式并对齐可行交互（工具栏 App 图标直开 + Finder 扩展能力边界说明）。
- [x] 增加“`一键添加到 Finder`”按钮（自动在 Finder 中定位 App，并提示最短拖拽安装动作）。
- [x] 深入分析 Go2Shell 开源实现（Finder 工具栏安装路径、AppleScript 打开逻辑）并对齐核心行为。
- [x] 调整为 Go2Shell 主路径：Finder Sync 仅保留右键能力，工具栏主入口改为 App 图标模式。
- [x] 增加 Finder 前台目录兜底解析（App 通过 `open urls` 未传参时，读取 Finder front window 目录直开）。
- [x] 新增 `PathBridgeLauncher` 轻量目标（无主窗口），用于 Finder 工具栏图标直开路径。
- [x] `一键添加到 Finder` 优先定位 `PathBridgeLauncher.app`，找不到时回退并提示先运行 Launcher。
- [x] 替换 App/Launcher 图标为本地 `Go2Shell.app` 图标资源，并完成构建验证。
- [x] 在 UI 明确提示“拖拽到 Finder 工具栏”为系统限制且不可绕过。
- [x] 精简设置界面：移除 Debug/Test Open/系统设置/重启 Finder 等冗余入口，并缩小窗口尺寸。
- [x] 修复 Warp 打开链路：优先按 bundle identifier 执行 `open -b`，失败再回退 `open -a`。
- [x] 修复 Launcher 与主 App 设置不一致（改为共享 suite defaults 存储，确保默认终端在两端一致）。
- [x] 新增 Kaku 终端适配器并接入终端注册表（自动显示已安装 Kaku）。
- [x] 提示区改为高可见告警样式并进一步收紧窗口尺寸（接近 Go2Shell 简洁体量）。
- [ ] 升级请求通道到 App Group/XPC（替换临时 DistributedNotification 方案）。
- [ ] 进行 Finder 真机联调：启用扩展后验证“右键单击直开 + 工具栏 Quick Open”链路（需要人工点击验证）。

## 回顾
- 已完成：2026-02-28 开源发布与维护性收敛。移除未使用模块（`TerminalLauncher`、`OpenRequestChannel`）与过时设置字段，相关测试已同步更新并通过。
- 已完成：Scheme 收敛到 `PathBridgeApp` / `PathBridgeLauncher` 两个共享方案；Workspace 侧自动方案在 Tuist 中默认保留但已本机隐藏，开发入口不再混乱。
- 已完成：图标生成脚本改为纯自绘自有风格（不依赖第三方素材），并同步覆盖 App/Launcher 两套 `AppIcon`。
- 已完成：新增 `scripts/release/publish_open_source.sh`，可一键自动执行 GitHub 源码仓库、Release 与 `lzy9527/homebrew-tap` cask 发布链路（需先 `gh auth login`）。
- 已完成：Homebrew 文档与 README 已统一为 `brew tap lzy9527/homebrew-tap`。
- 已完成：入口行为分流。`reopen` 仅在 Finder 前台时触发快开；Launchpad/Dock 普通启动不再直开终端，改为进入设置界面。
- 已完成：Finder 快开执行后切为 accessory 并自动退出进程，减少 Dock 常驻与运行指示。
- 已完成：设置页标题与副标题改为水平居中；产出新无签名包 `build/release/dmg/PathBridge-20260228-093717-82dd1a2.dmg`（SHA256 已生成）。
- 已完成：修复 Finder 自动化授权拦截。主 App 已补 `NSAppleEventsUsageDescription`，并在 `-1743` 时提示用户授权且自动打开“隐私与安全性 > 自动化”设置页。
- 已完成：重新 `tuist generate` 同步工程后回归通过，并产出新无签名包 `build/release/dmg/PathBridge-20260227-200058-82dd1a2.dmg`（SHA256 已生成）。
- 已完成：恢复单 Bundle 下 `reopen` 快开链路，Finder 工具栏图标点击可直接触发默认终端打开；并保留 deep-link 路径用于扩展直达。
- 已完成：语言切换入口下移到主界面右下，标题区裁切时仍可见；窗口顶部留白与高度同步上调，缓解 Tahoe/26 的遮挡问题。
- 已完成：回归通过 `xcodebuild test -scheme PathBridgeApp` 与 `xcodebuild build -scheme PathBridgeFinderExtension`，并产出新无签名包 `build/release/dmg/PathBridge-20260227-193843-82dd1a2.dmg`（SHA256 已生成）。
- 已完成：单 Bundle 回归修复，新增 Finder 前台触发的启动/重开快开逻辑，解决“点击无反应”。
- 已完成：设置页布局与窗口尺寸调整，缓解 Tahoe/26 上下遮挡问题；新包 `build/release/dmg/PathBridge-20260227-182219-82dd1a2.dmg`。
- 已完成：架构收敛为单 Bundle（移除 `PathBridgeLauncher`），Finder 扩展在 Host 未运行时直接以 `PathBridgeApp` 打开路径，不再依赖第二个 App。
- 已完成：打包链路切换为单 App，最新无签名产物 `build/release/dmg/PathBridge-20260227-180426-82dd1a2.dmg`（SHA256: `7eb8aeb7dd4e960d6caf85ad4e721d0a2bf7de80798f8e6f14eb129f64108359`）。
- 已完成：临时无签名打包成功，产物 `build/release/dmg/PathBridge-20260227-175027-82dd1a2.dmg`（含 `PathBridgeApp.app` + `PathBridgeLauncher.app`），可直接用于目标机型安装验证。
- 已完成：修复主窗口标题栏遮挡：header 改为稳定横向结构，并在 AppDelegate 中强制关闭 `fullSizeContentView`，避免内容侵入标题栏。
- 已完成：终端唤起兼容增强：`OpenCommandLauncher` 改为 “bundle id + 常见目录扫描 + app绝对路径启动” 策略，降低 Tahoe 26 下 LaunchServices 差异影响。
- 已完成：iTerm2/Warp/WezTerm/Ghostty/SystemTerminal/Kaku 的安装检测统一走兼容解析逻辑，支持 `~/Applications`、`/Applications/Setapp` 等路径。
- 已完成：图标改为 Go2Shell 基础样式二次设计（内部符号调整为 `^_^`），并同步替换 App/Launcher 全尺寸资源。
- 已完成：修复 Tahoe 26 顶部遮挡：主标题与语言切换改为同一行稳定布局并增加顶部留白。
- 已完成：`一键添加到 Finder` 缺失提示改为“开发/安装”双场景文案，不再在已安装场景误导用户去运行 Xcode scheme。
- 已完成：`make_dmg.sh` 默认将 `PathBridgeLauncher.app` 一并打包并签名到 DMG，避免安装后找不到 Launcher。
- 已完成：新发布包已公证并通过 Gatekeeper：`build/release/dmg/PathBridge-20260227-170211-82dd1a2.dmg`。
- 已完成：notarytool profile `pathbridge-notary` 已配置并通过凭据校验。
- 已完成：带签名与公证的 DMG 产物已生成并 stapled：`build/release/dmg/PathBridge-20260227-165051-82dd1a2.dmg`。
- 已完成：Gatekeeper 验证通过（`spctl`: `source=Notarized Developer ID`）。
- 已完成：签名配置自动化：新增 `scripts/release/configure_signing.sh`，可检测 Team/证书并一键写入 `DEVELOPMENT_TEAM`。
- 已完成：`Project.swift` 三个可签名目标（App/Launcher/FinderExtension）已固定 `DEVELOPMENT_TEAM=6K9FQJ7SA2`。
- 已完成：Developer ID 签名 DMG 已产出：`build/release/dmg/PathBridge-20260227-164404-82dd1a2.dmg`（SHA256 已生成）。
- 已完成：主窗口改为更紧凑尺寸（`408x336`）并增加顶部留白，标题字号与语言入口位置同步优化，降低 Tahoe 26 顶部遮挡风险。
- 已完成：重绘低饱和轻量图标并同步到 App/Launcher 两套 `AppIcon.appiconset`，Finder 工具栏视觉权重明显降低。
- 已完成：新增 `scripts/design/generate_light_icon.swift`，可一键再生全尺寸图标并保持两端主题一致。
- 已完成：回归通过：`xcodebuild test -scheme PathBridgeApp`、`xcodebuild build -scheme PathBridgeLauncher`。
- 已完成：新增 `scripts/release/make_dmg.sh`，支持本地一键 archive、DMG 打包、可选签名与公证（`DEVELOPER_ID_APPLICATION` + `NOTARYTOOL_PROFILE`）。
- 已完成：新增 `docs/signing-and-dmg.md`，覆盖证书、公证 profile、环境变量与验证命令；`README.md` 已补充 DMG 打包入口。
- 已完成：无签名链路验证通过，成功生成 `build/release/dmg/PathBridge-20260227-145758-401d97b.dmg`。
- 已完成：安装提示区从大字号改为紧凑可读样式，并移除路径级长文本，避免“感谢支持”按钮被顶出窗口。
- 已完成：`ExtensionGuideViewModel` 改为固定短文案策略，成功后仅提示“已在 Finder 打开 PathBridgeLauncher”，不再暴露本机绝对路径。
- 已完成：重绘 PathBridge v2 icon（橙色终端主体 + 桥形符号），并同步替换 App/Launcher 两套图标资源。
- 已完成：回归通过：`PathBridgeApp` 测试通过；`PathBridgeLauncher` 构建通过。
- 已完成：Kaku 打开链路切换为 `kaku start` 参数模型（`newTab -> --new-tab`，`newWindow -> --cwd`），并增加短等待 + stderr 失败特征检测，规避“退出码 0 但实际未连上”导致的假成功。
- 已完成：设置页终端下拉改为显示全部已适配终端，并对未安装项标注“(未安装)”；用户选中不可用终端时将明确收到“PathBridge 暂不支持”提示，不再隐式换系统 Terminal。
- 已完成：界面进一步收紧到 `430x360`，并将橘色系统限制提示升级为高对比告警条，提升可读性。
- 已完成：基于 Kaku 图标风格重绘 PathBridge 徽标并统一替换 App/Launcher 两套 icon 资源。
- 已完成：回归通过：`PathBridgeShared` / `PathBridgeTerminalAdapters` / `PathBridgeApp` 测试通过；`PathBridgeLauncher` / `PathBridgeFinderExtension` 构建通过。
- 已完成：Kaku 适配器切换到 CLI 路径（`kaku cli spawn --cwd`，新窗口带 `--new-window`），修复“能打开但不进入目录”问题；并补充 Kaku 启动参数测试。
- 已完成：设置窗口改为紧凑单列表单，默认尺寸收敛至 `460x420` 且按内容尺寸约束；二维码改为弹窗展示，主界面高度明显下降并更接近 Go2Shell 体量。
- 已完成：补齐终端链路可观测性。新增 `requestID` 穿透 Finder -> Host/Launcher -> 请求通道，并在设置读取来源、终端路由决策、`/usr/bin/open` 启动参数与 stderr 失败点输出结构化日志。
- 已完成：修复 Launcher 解析优先级，默认优先使用与当前构建同目录的 `PathBridgeLauncher.app`，避免同 bundle id 的旧 DerivedData 应用被误命中。
- 已完成：新增 Host/Launcher 启动自检日志（打印 bundlePath + version），用于快速确认 Finder 实际命中的二进制路径是否为当前构建。
- 已完成：修复 Launcher 设置读取路径。`AppSettingsStore` 新增 `hostContainerPreferences` 回退源，Launcher 在共享文件缺失时可从 Host 容器偏好读取默认终端与打开模式。
- 已完成：新增兼容性测试（旧 `OpenRequest` 无 `requestID` 仍可解码）与设置来源测试（default/userDefaults），并通过 Shared/Core/TerminalAdapters/App 测试及 Launcher/FinderExtension 构建。
- 已完成：修复默认终端路由与打开模式覆盖问题。Finder 扩展请求改为 `reuseCurrent`，Host 按设置解析；Launcher/Host 均优先尝试用户选中的终端适配器，扩展在 Host 不可达时优先回落到 Launcher。
- 已完成：新增测试覆盖 `OpenMode.reuseCurrent` 解析与 `preferredAdapter` 选择逻辑；`PathBridgeShared`、`PathBridgeCore`、`PathBridgeTerminalAdapters`、`PathBridgeApp` 测试均通过，`PathBridgeLauncher` 构建通过。
- 已完成：按 superpowers 官方 INSTALL 指引完成 clone + symlink，`~/.agents/skills/superpowers` 已指向 `~/.codex/superpowers/skills`。
- 已完成：完成参考方案拆解与第一版架构/发布规划。
- 已完成：已纳入 Kaku 终端支持要求，并给出适配实现策略。
- 已完成：已补齐交互细节、技术设计和终端兼容矩阵，可直接进入 PRD 冻结阶段。
- 已完成：已冻结入口优先级与多选默认策略（跨目录默认多窗口，可在设置切换）。
- 已完成：已新增发布门禁检查清单，发布动作可按门禁顺序执行。
- 已完成：仓库已独立初始化并绑定 Gitee 远程，开发骨架已落地。
- 已完成：本地可生成工程并通过 `xcodebuild` 构建，最小链路代码已接入。
- 已完成：扩展到主应用请求通道已打通（DistributedNotification + 直开兜底）。
- 已完成：已补齐基础 entitlements 与扩展入口排查步骤，便于真机联调。
- 已完成：已完成方案重构并冻结新范围（Phase 1 三终端 + 右键主入口直开 + UI 功能对标 + 支持区二维码）。
- 已完成：已修复二维码资源路径问题并完成四个 scheme 回归（`PathBridgeShared/Core/TerminalAdapters/App`）。
- 已完成：已明确 Finder 联调应运行 `PathBridgeApp`，并补充工具栏入口不可见时的启用/展示指引。
- 已完成：已完成设置页现代化改造（渐变背景、毛玻璃卡片、悬停动效、分区重排），并通过四个 scheme 回归测试。
- 已完成：已根据反馈回滚 UI 并恢复上一版结构，避免视觉风格偏差。
- 已完成：Finder 扩展工具栏点击已改为一步直开默认终端，不再弹出菜单。
- 已完成：`重启 Finder` 按钮已改为非 `killall` 路径，规避沙盒下进程拉起失败。
- 已完成：已处理 PNG CRC 报错并验证 `PathBridgeApp` 测试日志无 `imagePNG_error_break/IDAT`。
- 已完成：已完成 go2shell/openinterminal 方案调研并同步结论（工具栏 App 图标模式可实现一步直开；Finder Sync 工具栏菜单由系统驱动）。
- 已完成：已接入“`一键添加到 Finder`”按钮，点击后自动定位 App 并给出 `Command + 拖拽` 安装提示。
- 已完成：已按 Go2Shell 源码路径对齐“工具栏 App 图标直开”方案，并补齐 Finder 前台目录兜底。
- 已完成：Finder Sync 工具栏菜单入口已下线，避免与 Go2Shell 主交互冲突（保留右键入口）。
- 已完成：新增 `PathBridgeLauncher` 独立目标，支持无窗口启动并按 Finder 当前目录直开默认终端。
- 已完成：已将主 App 与 Launcher 图标替换为 `Go2Shell` 本地图标，视觉风格与对标目标一致。
- 已完成：已在界面直接提示 Finder 工具栏拖拽步骤属于系统限制，无法自动绕过最后一步。
- 已完成：设置窗口已收敛为精简版布局，界面尺寸接近 Go2Shell 的轻量感。
- 已完成：Warp 适配器改为 `open -b dev.warp...` 优先路径，减少误回退到系统 Terminal。
- 已完成：Launcher 与主 App 现使用共享 suite defaults，默认终端（如 Warp/Kaku）选择可正确继承到工具栏点击链路。
- 已完成：已接入 Kaku 终端（bundle id: `fun.tw93.kaku`）并纳入默认终端选择列表。
- 风险：Finder 扩展与终端自动化在不同 macOS 版本存在兼容性差异，需要尽早做真机矩阵验证。
- 下一步：按 `docs/plans/2026-02-27-finder-direct-open-and-ui-redesign-implementation-plan.md` 进入实现与联调。
