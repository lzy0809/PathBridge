# Repository Guidelines

## 项目结构与模块组织
本仓库当前以 macOS 桌面应用方案为主（Swift + Tuist）：
- `docs/`：产品规划、交互规格、技术设计、发布清单。
- `tasks/`：任务清单与经验教训沉淀。
- `Apps/`：主应用（后续实现阶段创建）。
- `Extensions/`：Finder 扩展（后续实现阶段创建）。
- `Packages/`：Core / TerminalAdapters / Shared（后续实现阶段创建）。

目录命名优先按功能边界划分，避免无边界 `utils` 聚合。

## 构建、测试与开发命令
在仓库根目录执行（实现阶段）：
- `tuist install`：安装 Tuist 依赖。
- `tuist generate`：生成 Xcode 工程/工作区。
- `xcodebuild archive -scheme Go2ShellProApp -configuration Release ...`：产出归档包。
- `codesign --verify --deep --strict --verbose=2 <App.app>`：签名校验。
- `xcrun notarytool submit <dmg> --keychain-profile <profile> --wait`：提交公证。
- `xcrun stapler validate <dmg|app>`：验证公证 stapling 结果。

## 代码风格与命名规范
- Swift 命名遵循 Apple 规范：类型 `PascalCase`，属性/方法 `camelCase`。
- 文件名与主类型一致（如 `TerminalAdapterRegistry.swift`）。
- 优先协议化设计（`TerminalAdapter`、`ActionExecutor`），避免超大类。
- Finder 扩展与主应用通信必须通过明确定义的数据模型，不传裸字符串命令。

## 测试规范
- 单元测试覆盖 Core 与策略层：路径归一化、终端选择、错误映射。
- 适配器测试覆盖 installed/not-installed/timeout/fallback 四类路径。
- 回归测试覆盖 Finder 关键场景：单选目录、单选文件、多选同目录、多选跨目录。
- 发布前必须完成签名、公证与 Gatekeeper 验证命令检查。

## 提交与 PR 规范
仓库暂无历史约定，默认使用 Conventional Commits：
- `feat: add user validation`
- `fix: handle nil config`
- `docs: update setup steps`

PR 需包含：
- 变更摘要与行为影响。
- 关联任务/Issue（如有）。
- 测试证据（命令与关键结果）。
- 兼容性、迁移或配置变更说明（如有）。

## 工作流编排（强制）
1. 规划节点默认  
- 非平凡任务（3 步以上或涉及架构决策）默认进入规划模式。  
- 发生偏航时立即停止并重新规划，不允许硬推。  
- 规划用于构建与验证两个阶段。  
- 先写清晰规格，减少歧义。  

2. 子代理策略  
- 使用子代理隔离研究、探索、并行分析，保持主上下文整洁。  
- 复杂问题优先增加子代理并行计算。  
- 每个子代理只做单一任务。  

3. 自我改进循环  
- 用户每次纠正后，更新 `tasks/lessons.md`。  
- 将错误模式固化为规则，防止重复发生。  
- 持续迭代教训直至错误率下降。  
- 会话开始先回顾当前项目相关教训。  

4. 完成前验证  
- 未经验证不得标记完成。  
- 必要时对比主版本与修改后行为差异。  
- 自检标准：是否达到资深工程师可接受质量。  
- 运行测试、检查日志并给出正确性证据。  

5. 追求优雅（平衡）  
- 非平凡修改前先评估是否有更优雅方案。  
- 若修复像临时补丁，应回到根因并实现可维护解。  
- 简单直接的问题避免过度设计。  
- 完成前主动挑战方案质量。  

6. 自主修复缺陷  
- 收到缺陷报告后直接定位并修复，不要求用户手把手指导。  
- 以日志、报错、失败测试为线索闭环解决。  
- 减少用户上下文切换。  
- 主动修复失败的 CI 测试。  

## 任务管理（强制）
7. 先规划：将计划写入 `tasks/todo.md`，使用可勾选项。  
8. 验证计划：实施前先确认计划可执行。  
9. 跟踪进度：完成后及时勾选。  
10. 解释变更：每一步提供高层摘要。  
11. 记录结果：在 `tasks/todo.md` 增加回顾。  
12. 捕获教训：纠正后更新 `tasks/lessons.md`。  

## 核心原则
- 简洁优先：只改必要代码，降低引入风险。  
- 拒绝偷懒：定位根因，不做临时性补丁，保持高工程标准。  
- 最小影响：控制改动范围，避免额外副作用。  

## 沟通语言
- 默认使用中文与用户沟通；仅在用户明确要求时切换语言。
