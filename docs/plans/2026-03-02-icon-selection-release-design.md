# 2026-03-02 Icon 方案评估与发布设计

## 背景与目标
- 输入素材：`/Users/liangzhiyuan/Desktop/归档` 下两套图标（v1/v2），分别包含 App 与 Finder 图。
- 目标：在不再二次调整设计的前提下，选出一套接入 `PathBridgeApp` + `PathBridgeLauncher`，并同步走 GitHub Release 与 Homebrew Cask 发布链路。

## 方案对比

### 方案 A（v1）
- App：中心主图形更接近“文件”轮廓，语义偏文档。
- Finder：横向胶囊外框，工具栏识别较直观。
- 风险：与“打开文件夹到终端”的语义存在偏差，和 Finder 入口语义不完全一致。

### 方案 B（v2）
- App：中心图形为明确“文件夹”轮廓，语义更贴合产品主功能。
- Finder：圆角方形外框，与 App 图形语言一致；在 16px 下线条保留完整。
- 风险：Finder 外框在极小尺寸下略重，但仍可读。

### 方案 C（混搭：v2 App + v1 Finder）
- 优点：Finder 小尺寸辨识度略高。
- 风险：破坏同一品牌语言一致性，与历史“主 App 与 Finder 保持统一符号系统”经验冲突。

## 推荐方案
- 采用 **方案 B（全量 v2）**。
- 理由：
  1. 语义一致：文件夹符号直接表达“打开目录”。
  2. 双端一致：App/Finder 视觉语言统一，减少漂移。
  3. 可维护性：后续脚本与资产管理只维护单一基线。

## 接入与发布设计
- 图标接入：以 1024 源图缩放生成 `AppIcon.appiconset` 全尺寸资源。
- 验证门禁：
  - `xcodebuild test -scheme PathBridgeApp`
  - `xcodebuild build -scheme PathBridgeLauncher`
- 发布链路：
  - 先用 `scripts/release/make_dmg.sh` 产出 DMG 与 sha256。
  - 再用 `scripts/release/publish_open_source.sh --version --dmg` 更新 GitHub Release 与 Homebrew Tap Cask。
