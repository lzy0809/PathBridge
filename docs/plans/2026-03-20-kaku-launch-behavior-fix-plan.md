# Kaku Launch Behavior Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修复 Finder 快开使用 Kaku 时的多实例 Dock 图标与窗口未前置问题，同时兼容当前 Kaku 0.7.x 的实际 CLI 能力。

**Architecture:** 保持 Finder -> Launcher -> TerminalAdapter 的现有链路不变，仅收敛 `KakuAdapter` 的启动能力探测、命令选择和前台激活行为。优先使用单实例友好的 GUI 启动命令，避免把“每次新进程”作为默认路径。

**Tech Stack:** Swift, AppKit, XCTest, Tuist/Xcodebuild.

---

### Task 1: 为 Kaku 能力探测补失败测试

**Files:**
- Modify: `Packages/TerminalAdapters/Tests/TerminalAdapterRegistryTests.swift`

**Step 1: Write the failing test**
- 新增测试覆盖：
  - `kaku-gui` 的 `start --cwd` / `start --new-tab --cwd`
  - `kaku` 仅在显式支持 `cli spawn` 时才生成旧策略
  - `newWindow` 默认不再包含 `--always-new-process`

**Step 2: Run test to verify it fails**
- Run: `xcodebuild test -scheme PathBridgeTerminalAdaptersTests -only-testing:PathBridgeTerminalAdaptersTests/TerminalAdapterRegistryTests`
- Expected: FAIL，说明当前策略仍是旧的硬编码路径。

### Task 2: 最小实现 Kaku 启动能力探测与激活

**Files:**
- Modify: `Packages/TerminalAdapters/Sources/KakuAdapter.swift`

**Step 1: Write minimal implementation**
- 将 Kaku 启动从“固定命令数组”改为“按可执行文件能力建模”：
  - 为候选可执行文件解析支持的命令（`start` / `cli spawn` / `--new-tab`）
  - 优先 `kaku-gui start`
  - 去掉默认链路中的 `--always-new-process`
- 启动成功后对 `fun.tw93.kaku` 做显式前台激活。

**Step 2: Run targeted tests**
- Run: `xcodebuild test -scheme PathBridgeTerminalAdaptersTests -only-testing:PathBridgeTerminalAdaptersTests/TerminalAdapterRegistryTests`
- Expected: PASS

### Task 3: 回归验证

**Files:**
- Modify: `tasks/todo.md`

**Step 1: Run broader verification**
- Run: `xcodebuild test -scheme PathBridgeTerminalAdaptersTests`
- Run: `xcodebuild build -scheme PathBridgeLauncher`

**Step 2: Record outcome**
- 在 `tasks/todo.md` 勾选完成项，并补一条回顾记录。
