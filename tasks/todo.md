# Todo

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
