# Homebrew Cask 发布说明

目标 tap 仓库：`lzy0809/homebrew-tap`

## 1. 创建 tap 仓库

```bash
gh repo create lzy0809/homebrew-tap --public
```

## 2. cask 文件结构

在 tap 仓库创建：

- `Casks/pathbridge.rb`

示例：

```ruby
cask "pathbridge" do
  version "0.2.0"
  sha256 "REPLACE_WITH_DMG_SHA256"

  url "https://github.com/lzy0809/PathBridge/releases/download/v#{version}/PathBridge-REPLACE_WITH_DMG_NAME.dmg"
  name "PathBridge"
  desc "Open Finder directory in your selected terminal"
  homepage "https://github.com/lzy0809/PathBridge"

  app "PathBridgeApp.app"

  zap trash: [
    "~/Library/Containers/com.liangzhiyuan.pathbridge",
    "~/Library/Preferences/com.liangzhiyuan.pathbridge.plist"
  ]
end
```

## 3. 用户安装方式

```bash
brew tap lzy0809/tap
brew install --cask lzy0809/tap/pathbridge
```

## 4. 升级发布

每次新版本只需更新：

- `version`
- `sha256`
- `url`

提交并推送到 `lzy0809/homebrew-tap` 后，用户执行：

```bash
brew update
brew upgrade --cask lzy0809/tap/pathbridge
```
