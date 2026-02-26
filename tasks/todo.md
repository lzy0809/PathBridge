# Todo

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
- [ ] 升级请求通道到 App Group/XPC（替换临时 DistributedNotification 方案）。
- [ ] 进行 Finder 真机联调：启用扩展后验证工具栏菜单可直接打开 Terminal（需要人工点击验证）。

## 回顾
- 已完成：完成参考方案拆解与第一版架构/发布规划。
- 已完成：已纳入 Kaku 终端支持要求，并给出适配实现策略。
- 已完成：已补齐交互细节、技术设计和终端兼容矩阵，可直接进入 PRD 冻结阶段。
- 已完成：已冻结入口优先级与多选默认策略（跨目录默认多窗口，可在设置切换）。
- 已完成：已新增发布门禁检查清单，发布动作可按门禁顺序执行。
- 已完成：仓库已独立初始化并绑定 Gitee 远程，开发骨架已落地。
- 已完成：本地可生成工程并通过 `xcodebuild` 构建，最小链路代码已接入。
- 已完成：扩展到主应用请求通道已打通（DistributedNotification + 直开兜底）。
- 风险：Finder 扩展与终端自动化在不同 macOS 版本存在兼容性差异，需要尽早做真机矩阵验证。
- 下一步：做 Finder 真机联调，确认工具栏点击行为与权限引导流程。
