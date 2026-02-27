# Finder 直达与 UI 重构设计（Phase 1）

## 1. 背景与目标
- 背景：当前 Finder 工具栏行为是“点击后弹菜单再执行”，主应用 UI 仅静态说明文本，缺少可配置能力与交互元素。
- 目标：对标 go2shell 的功能体验，用户可快速打开默认终端、配置默认参数、完成 Finder 扩展启用引导，并在应用内展示感谢支持二维码。
- 范围：仅覆盖 Phase 1（不上架 App Store，DMG 分发，首发终端限定 Terminal/iTerm2/Warp）。

## 2. 关键约束与结论
- Finder Sync 限制：工具栏按钮点击后由系统展示扩展返回的菜单，扩展侧无法把“工具栏点击”改为完全无菜单直开。
- 合规策略：
  - 保留工具栏入口，但菜单最小化（首项即“Quick Open in <Default Terminal>”）。
  - 将“右键菜单主入口”定义为默认高频路径：`Open in <Default Terminal>` 单击执行。
- 终端支持冻结：v0.1 仅做 Terminal / iTerm2 / Warp，Kaku/WezTerm/Ghostty 后续迭代。

## 3. 交互设计（方案 B 落地）
### 3.1 Finder 入口
- 右键菜单（主入口）：
  - 条目：`Open in <Default Terminal>`。
  - 行为：选中后直接执行，不再弹二级菜单。
- 工具栏菜单（降级入口）：
  - 第 1 项：`Quick Open in <Default Terminal>`（默认动作）。
  - 第 2 项：`Open in...`（可选，列出已安装终端）。
  - 第 3 项：`Preferences...`（打开主应用设置）。

### 3.2 主应用 UI（功能对标优先）
- `General` 区：
  - 默认终端下拉（仅显示已安装；首发 3 终端）。
  - 默认打开模式（新窗口/新标签/复用当前窗口）。
  - 打开后是否激活到前台。
- `Command Template` 区：
  - 输入框支持模板；默认值：`cd %PATH_QUOTED%; clear; pwd`。
  - “恢复默认”按钮。
  - Debug 模式下显示解析后的最终命令预览。
- `Finder Extension` 区：
  - 按钮：`打开系统设置并定位 Extensions`。
  - 辅助按钮：`重启 Finder`（执行 Finder Relaunch 指引）。
  - 状态提示文案（可用/未启用/未注册）。
- `Quick Actions` 区：
  - 按钮：`Test Open`（用当前 Finder 路径或用户目录做一次链路验证）。
- `Support` 区：
  - 展示两张本地二维码图片（“感谢支持”），可点击放大预览。

## 4. 数据流与模块责任
- Finder Extension：采集 selected/targeted URLs，构造 `OpenRequest` 并发给 Host App；主应用不可达时本地兜底打开 Terminal。
- Host App：
  - 接收请求并读取用户设置。
  - 通过 `TerminalAdapterRegistry` 选择默认终端适配器执行。
  - 失败时按策略回退到系统 Terminal。
- Core：
  - `SelectionResolver` 负责路径标准化与去重。
  - `CommandTemplateResolver` 负责占位符替换与预览。
- Shared：
  - 承载 `OpenRequest`、`OpenMode`、配置模型与通知通道常量。

## 5. 错误处理与可观测性
- 失败提示分级：
  - 终端不存在：提示并回退。
  - 路径不可访问：提示权限问题。
  - 通信失败：扩展侧直接兜底。
- 日志：主应用保存最近 100 条执行记录（本地）。
- 不做云同步与遥测。

## 6. 测试与验收
- 单元测试：
  - 路径归一化（文件->父目录、多选去重、符号链接）。
  - 命令模板占位符解析与默认模板回退。
  - 终端选择策略（首发 3 终端 + 系统回退）。
- 联调回归：
  - Finder：单目录、单文件、多选同目录、多选跨目录。
  - UI：默认终端切换生效、参数保存生效、扩展引导按钮有效。
- 验收标准：
  - 主路径（右键入口）单击可直达默认终端。
  - 工具栏入口首项可快速执行默认动作。
  - UI 完成功能对标（默认终端/参数模板/扩展引导/感谢支持区）。

## 7. 非目标（本轮不做）
- App Store 上架流程。
- Homebrew 分发自动化。
- 首发外终端（Kaku/WezTerm/Ghostty）完整适配。
