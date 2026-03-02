# Icon Selection + Release Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 选择 v2 图标方案并完成项目资源接入、构建验证、GitHub Release 与 Homebrew Cask 同步。

**Architecture:** 仅替换资产层（`AppIcon.appiconset`）不改业务逻辑；发布沿用现有 `make_dmg.sh` 与 `publish_open_source.sh` 自动链路。图标源采用用户提供 1024 png，下采样覆盖 App/Launcher 全尺寸资源。

**Tech Stack:** Swift/Tuist/Xcodebuild, bash, sips, GitHub CLI (`gh`)

---

### Task 1: 评估并冻结图标方案

**Files:**
- Modify: `tasks/todo.md`
- Create: `docs/plans/2026-03-02-icon-selection-release-design.md`

**Step 1: 完成 v1/v2 可读性评估并记录推荐方案**

执行：人工比对 1024/128/16 尺寸可读性，冻结方案 B（v2）。

**Step 2: 在 todo 中登记本轮任务并标记进度**

执行：更新 `tasks/todo.md` 新增“2026-03-02，双方案 Icon 评估与发布同步”。

### Task 2: 接入 v2 图标到 App 与 Finder

**Files:**
- Modify: `Apps/PathBridgeApp/Resources/Assets.xcassets/AppIcon.appiconset/*`
- Modify: `Apps/PathBridgeLauncher/Resources/Assets.xcassets/AppIcon.appiconset/*`

**Step 1: 由 1024 源图生成各尺寸图标资源**

Run:
```bash
APP_SRC="/Users/liangzhiyuan/Desktop/归档/app_icon_1024_v2.png"
FINDER_SRC="/Users/liangzhiyuan/Desktop/归档/finder_icon_1024_v2.png"
# 使用 sips 覆盖 16/32/64/128/256/512/1024 到两个 appiconset
```
Expected: 两个 `AppIcon.appiconset` 的 10 个 png 全部更新。

**Step 2: 验证关键源图哈希与目标 1024 图一致**

Run:
```bash
shasum -a 256 \
  /Users/liangzhiyuan/Desktop/归档/app_icon_1024_v2.png \
  /Users/liangzhiyuan/Desktop/go2/Apps/PathBridgeApp/Resources/Assets.xcassets/AppIcon.appiconset/icon-512@2x.png
```
Expected: hash 一致（Launcher 同理）。

### Task 3: 构建与测试验证

**Files:**
- Modify: `tasks/todo.md`

**Step 1: 运行 App 测试**

Run: `xcodebuild test -workspace PathBridge.xcworkspace -scheme PathBridgeApp -destination 'platform=macOS'`
Expected: 测试通过。

**Step 2: 运行 Launcher 构建**

Run: `xcodebuild build -workspace PathBridge.xcworkspace -scheme PathBridgeLauncher -destination 'platform=macOS'`
Expected: 构建通过。

### Task 4: 发布到 GitHub 与 Homebrew

**Files:**
- Modify: `tasks/todo.md`

**Step 1: 生成 DMG 与 sha256**

Run: `scripts/release/make_dmg.sh`
Expected: 在 `build/release/dmg/` 生成 `PathBridge_v<version>.dmg` 及 `.sha256`。

**Step 2: 发布 GitHub Release + Homebrew Cask**

Run:
```bash
scripts/release/publish_open_source.sh \
  --version <version> \
  --dmg build/release/dmg/<dmg_name>
```
Expected: GitHub 新 tag/release 上传成功；`lzy0809/homebrew-tap` 的 `Casks/pathbridge.rb` 更新。

**Step 3: 回写任务回顾**

执行：在 `tasks/todo.md` 的回顾区新增本次版本、dmg 路径、sha、release 结果。

### Task 5: 提交变更

**Files:**
- Modify: 图标资产与任务/计划文档

**Step 1: 提交代码**

Run:
```bash
git add Apps/PathBridgeApp/Resources/Assets.xcassets/AppIcon.appiconset \
        Apps/PathBridgeLauncher/Resources/Assets.xcassets/AppIcon.appiconset \
        docs/plans/2026-03-02-icon-selection-release-design.md \
        docs/plans/2026-03-02-icon-selection-release-implementation-plan.md \
        tasks/todo.md

git commit -m "feat: adopt v2 icon set and publish latest release"
```
Expected: 本次图标与发布记录形成独立提交。
