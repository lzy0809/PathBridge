# PathBridge Go2Shell 100% 对标重构设计（激进方案）

## 1. 目标冻结（按用户要求）
- 行为目标：Finder 工具栏点击 PathBridge 图标后，直接打开用户选择的终端到当前 Finder 目录，不弹菜单、不弹设置页。
- 入口目标：点击 Launchpad/Dock 的 PathBridge 图标只打开设置界面，不执行快开。
- 驻留目标：执行快开时不在 Dock 常驻，不保留“正在运行”视觉噪音。
- 安装目标：提供 Go2Shell 风格“一键添加到 Finder”能力（激进自动注入），并保留手动拖拽兜底。
- 功能目标：在现有满意 UI 基础上，仅增强稳定性与终端覆盖，不再引入 UI 复杂化。

## 2. 对标取证结论（本机安装版）
- `/Applications/Go2Shell.app` 为主设置 App。
- `/Applications/Go2Shell.app/Contents/MacOS/Go2ShellHelper.app` 为内嵌 Helper，且 `LSUIElement=1`。
- 主程序二进制可见关键方法：`installHelper`、`writeToolbarAndRelaunchFinderWithDict`、`relaunchFinder`、`createToolbarConfigurationBrowserDictionary`。
- Helper 二进制可见关键方法：`pathToFrontFinderWindow`、`openTerminalWithIdentifier:inNewWindow:`。
- 结论：Go2Shell 是“设置 App + 无 Dock Helper + Finder toolbar 配置注入”的双角色体系，不是 FinderSync 主导。

## 3. 方案对比（2-3 选项）
### A. Go2Shell 激进对标（推荐）
- 架构：PathBridge 主 App + 内嵌 PathBridgeHelper（LSUIElement）+ 激进 Finder toolbar 注入器。
- 优点：用户体验最接近 Go2Shell；能满足“点击即开终端、不弹 UI”。
- 缺点：依赖 Finder 配置结构，macOS 大版本可能有兼容风险，需要回归策略。

### B. Helper 对标 + 手动拖拽安装
- 架构：保留 Helper 快开，但不写 Finder 配置，只做定位并提示 Command 拖拽。
- 优点：稳定性更高。
- 缺点：和 Go2Shell“激进一键添加”不完全一致。

### C. 继续 FinderSync 主路线
- 架构：Host + FinderSync + deep-link/reopen 分流。
- 优点：公开 API 路线。
- 缺点：与目标体验冲突，已被多轮验证为不丝滑。

> 结论：按你的要求，采用 A。

## 4. 目标架构（与 Go2Shell 一致）
### 4.1 包结构（对外仍单 App 分发）
- `PathBridge.app`（可见设置应用，Regular App）
- `PathBridge.app/Contents/MacOS/PathBridgeHelper.app`（内嵌执行器，LSUIElement）
- FinderSync 可降级为备用入口（右键）或后续移除，主入口切到 Helper。

### 4.2 角色边界
- 主 App：设置页、终端选择、命令模板、打开方式、语言、赞赏页、一键安装按钮。
- Helper：无窗口启动，读取 Finder front directory，执行终端打开，记录日志，完成即退出。
- 安装器模块：负责 Finder toolbar 配置注入与 Finder 重启。

### 4.3 配置共享
- 主 App 与 Helper 使用同一配置源（`app-settings.json` + 明确回退链）。
- 快开链路只读配置，不依赖主 App 进程存活。

## 5. 关键链路设计
### 5.1 Finder 工具栏点击链路
1. Finder 工具栏点击 PathBridgeHelper 图标。
2. Helper 启动后读取 Finder 前台窗口目录（Apple Events）。
3. 按用户配置终端 + 模式（new tab/new window）+ 命令模板执行。
4. 成功后 Helper 立即 `terminate`，Dock 不常驻。

### 5.2 Launchpad/Dock 点击链路
1. 启动主 App。
2. 只展示设置窗口，不触发快开逻辑。

### 5.3 一键添加到 Finder（激进）
1. 主 App 定位 Helper 绝对路径。
2. 读取并修改 Finder toolbar 配置字典（`com.apple.finder.plist` 相关键）。
3. 插入 Helper toolbar item（包含 item identifiers/plists/default items）。
4. 写回配置后重启 Finder。
5. 检测成功状态并提示完成；失败时回退到“定位+Command 拖拽”。

## 6. 终端适配策略（保持你现有能力并增强）
- 适配器由 Helper 直接调用，不走 Host 转发。
- 失败策略：不再兜底系统 Terminal；直接 toast“该终端当前暂不支持/未安装”。
- 支持矩阵：Terminal、iTerm2、Warp、WezTerm、Ghostty、Kaku。
- 打开模式：统一支持 `newTab` / `newWindow`；逐终端映射参数，Kaku 单独修复其 `newTab` 行为。

## 7. 合规与分发（对外发布）
- 为接近 Go2Shell 行为，主 App/Helper 建议去掉 App Sandbox（Developer ID 分发不要求 sandbox）。
- 保留并完善 Apple Events 使用说明（主 App 与 Helper 都要有权限描述）。
- 使用 Developer ID Application 签名并 notarize，继续 DMG 分发。

## 8. 稳定性与风控
- 风险 1：Finder toolbar 配置键在 macOS 版本变化。
  - 应对：注入前做结构探测；不匹配则自动走手动拖拽兜底。
- 风险 2：Apple Events 权限拒绝（`-1743`）。
  - 应对：首次引导用户在系统设置授权 Finder 自动化。
- 风险 3：第三方终端版本差异。
  - 应对：适配器增加命令回显、stderr 特征检测、明确错误提示。

## 9. 验收标准（必须全部满足）
- 点击 Finder 工具栏 PathBridge 图标：直接打开选定终端到目标目录。
- 全程不弹菜单、不弹设置窗口。
- 主 App 点击后仅打开设置 UI，不误触发终端。
- 快开流程不在 Dock 常驻。
- 一键添加到 Finder 在兼容系统中自动完成；不兼容时给出明确兜底步骤。
- 终端选择准确生效，不再“总是系统 Terminal”。

## 10. 实施里程碑
- M1：恢复 Helper 架构并完成“Finder 点击直开”闭环。
- M2：实现激进 Finder toolbar 注入 + Finder 重启 + 失败兜底。
- M3：终端适配回归（含 Kaku newTab/newWindow）。
- M4：签名、公证、DMG 产出与跨机型验证。

---
本设计明确采用“Go2Shell 激进对标”而非最小改动路线，后续实现按此文档冻结执行。
