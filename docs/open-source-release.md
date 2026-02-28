# PathBridge 开源发布流程

本文档用于将 PathBridge 源码 + DMG 公开到 GitHub，并产出可下载的 Release。

## 1. 目标仓库

- 源码仓库：`https://github.com/lzy0809/PathBridge`
- Homebrew tap：`https://github.com/lzy0809/homebrew-tap`

## 2. 一次性准备

1. 安装 GitHub CLI（gh）
2. 登录 GitHub：

```bash
gh auth login
```

3. 确认账号状态：

```bash
gh auth status
```

## 3. 一键自动化（推荐）

在仓库根目录执行：

```bash
scripts/release/publish_open_source.sh \
  --version 0.1.0 \
  --dmg build/release/dmg/PathBridge-xxxx.dmg
```

脚本会自动完成：

- 创建/校验 `lzy0809/PathBridge`
- 推送当前分支到 GitHub
- 创建/更新 Release（上传 DMG + SHA256）
- 创建/校验 `lzy0809/homebrew-tap`
- 生成并推送 `Casks/pathbridge.rb`

## 4. 手动方式（备用）

### 4.1 创建源码仓库并推送

在本仓库根目录执行：

```bash
gh repo create lzy0809/PathBridge --public --source=. --remote=origin --push
```

如果你已经有 `origin`，可改用：

```bash
git remote set-url origin git@github.com:lzy0809/PathBridge.git
git push -u origin master
```

### 4.2 生成并上传 DMG Release

1. 本地打包：

```bash
scripts/release/make_dmg.sh
```

2. 打 tag：

```bash
git tag v0.1.0
git push origin v0.1.0
```

3. 发布（上传 DMG + SHA256）：

```bash
gh release create v0.1.0 \
  build/release/dmg/PathBridge-*.dmg \
  build/release/dmg/PathBridge-*.dmg.sha256 \
  --title "PathBridge v0.1.0" \
  --notes "Initial public release"
```

## 5. Release 检查项

- DMG 可挂载，包含且仅包含 `PathBridgeApp.app`
- `PathBridgeApp.app` 内嵌 `PathBridgeLauncher.app`
- README 与 Release notes 的安装步骤一致
- SHA256 文件可用于校验下载完整性
