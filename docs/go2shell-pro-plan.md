# go2shell Pro 产品与实现规划（V1）

## 0. 文档导航
- 交互规格：`docs/go2shell-pro-interaction-spec.md`
- 技术设计：`docs/go2shell-pro-technical-design.md`
- 终端兼容矩阵：`docs/go2shell-pro-terminal-matrix.md`
- 发布门禁清单：`docs/release-gate-checklist.md`

## 1. 目标与范围
目标：做一个比 go2shell 更强的 macOS 工具，保留“在 Finder 中一键打开当前目录到终端”的核心体验，并扩展到多终端、多动作和可配置工作流。

阶段划分：
- Phase 1（优先）：可发布 DMG 的稳定版（Finder 扩展 + 多终端支持 + 偏好设置）。
- Phase 2（后置）：`brew install` 分发（Cask/tap 自动化）。

## 2. 参考 MoePeek 的可复用做法
基于 `cosZone/MoePeek` 调研结论：
- 使用 Tuist + SPM 管理工程（`Project.swift` + `Package.swift`）。
- GitHub Actions 在 macOS runner 上执行 `tuist generate` + `xcodebuild archive`。
- 使用 `create-dmg` 生成 DMG，并随 release 上传 ZIP/DMG。
- 版本以 git tag（`v*`）驱动发布。

可直接借鉴：Tuist 工程化、tag 驱动发版、DMG 自动打包流水线。

## 3. 产品能力设计（Phase 1）
核心场景：
- Finder 右键主入口：`Open in <Default Terminal>`（单击直开）。
- Finder 工具栏保留最小菜单：首项 `Quick Open in <Default Terminal>`（因 Finder Sync 平台限制，工具栏点击无法完全无菜单直开）。
- 支持文件夹、文件（自动取父目录）、多选（批量开标签页或多窗口）。

高级能力：
- 终端适配器：Phase 1 冻结 Terminal、iTerm2、Warp；WezTerm、Ghostty、Kaku 后续迭代接入。
- 动作模板：新窗口、新标签、在当前窗口打开、执行启动命令（如 `source .env && npm run dev`）。
- 路径处理：空格转义、符号链接解析、网络卷与权限失败提示。
- 偏好设置：默认终端、默认参数模板（含默认值）、是否复用窗口、启动后焦点策略、Finder 扩展启用引导。
- 支持区：展示两张本地“感谢支持”二维码。

非目标（Phase 1 不做）：云同步、插件市场、复杂脚本编排 UI。

## 4. 技术架构（建议）
工程结构（Tuist 多 target）：
- `Apps/Go2ShellProApp`：主应用（设置、状态栏、日志）。
- `Extensions/FinderSyncExtension`：Finder 扩展入口。
- `Packages/Core`：路径解析、动作执行器、日志与配置。
- `Packages/TerminalAdapters`：终端适配协议与各终端实现。
- `Packages/Shared`：模型与 App Group 通信协议。

关键抽象：
- `TerminalAdapter` 协议：`isInstalled/open(urls, mode, command)`。
- `ActionExecutor`：把 Finder 选择集转换为可执行动作。
- `SelectionResolver`：文件/目录规范化与错误分级。
- `KakuAdapter`：优先尝试 CLI 方式（`kaku cli spawn --new-window --cwd <path>`），失败时回退 `open -a Kaku <path>`。

Finder 扩展与主应用通信：
- 优先 App Group + distributed notification / XPC（轻量命令消息）。
- 失败时直接由扩展执行最小动作（兜底）。

## 5. 发布与交付

### 5.1 分发模式说明
本项目**不上架 App Store**，采用以下分发方式：
- **Phase 1**：DMG 直接分发（GitHub Release）
- **Phase 2**：Homebrew Cask 安装（`brew install --cask YOUR_ORG/go2shell-pro/go2shell-pro`）

### 5.2 Phase 1（DMG 分发）

#### 签名与公证（非 App Store 必需）
由于不走 App Store，必须完成以下步骤才能在用户机器上正常运行：

| 步骤 | 命令/操作 | 说明 |
|------|-----------|------|
| 1. Developer ID 证书 | Apple Developer 后台申请 | 类型：`Developer ID Application` |
| 2. App 签名 | `codesign --deep --force --sign "Developer ID Application: <Name>" --options runtime Go2ShellPro.app` | `--options runtime` 启用 Hardened Runtime |
| 3. 打包 DMG | `create-dmg` 工具 | 签名后的 .app 打入 DMG |
| 4. DMG 签名 | `codesign --sign "Developer ID Application: <Name>" go2shell-pro.dmg` | DMG 本身也需签名 |
| 5. 公证提交 | `xcrun notarytool submit go2shell-pro.dmg --keychain-profile "notary-profile" --wait` | 推荐使用 keychain profile（或 API Key）提交到 Apple Notary Service |
| 6. Stapling | `xcrun stapler staple go2shell-pro.dmg` | 将公证结果嵌入 DMG |

#### CI 流水线（GitHub Actions）
```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Tuist
        run: |
          brew install tuist
          tuist install

      - name: Generate Xcode Project
        run: tuist generate

      - name: Build Archive
        run: |
          xcodebuild archive \
            -project Go2ShellPro.xcodeproj \
            -scheme Go2ShellProApp \
            -archivePath build/Go2ShellPro.xcarchive \
            -configuration Release

      - name: Export App
        run: |
          xcodebuild -exportArchive \
            -archivePath build/Go2ShellPro.xcarchive \
            -exportPath build/export \
            -exportOptionsPlist ExportOptions.plist

      - name: Code Sign App
        env:
          SIGNING_IDENTITY: ${{ secrets.DEVELOPER_ID_APPLICATION }}
        run: |
          codesign --deep --force --verify --verbose \
            --sign "$SIGNING_IDENTITY" \
            --options runtime \
            build/export/Go2ShellPro.app

      - name: Create DMG
        run: |
          brew install create-dmg
          create-dmg \
            --volname "Go2Shell Pro" \
            --volicon "Assets/AppIcon.icns" \
            --window-pos 200 120 \
            --window-size 800 450 \
            --icon-size 100 \
            --icon "Go2ShellPro.app" 200 190 \
            --hide-extension "Go2ShellPro.app" \
            --app-drop-link 600 185 \
            --skip-jenkins \
            go2shell-pro-${{ github.ref_name }}.dmg \
            build/export/

      - name: Sign & Notarize DMG
        env:
          SIGNING_IDENTITY: ${{ secrets.DEVELOPER_ID_APPLICATION }}
          NOTARY_PROFILE: ${{ secrets.NOTARYTOOL_PROFILE }}
        run: |
          # Sign DMG
          codesign --sign "$SIGNING_IDENTITY" go2shell-pro-${{ github.ref_name }}.dmg

          # Notarize
          xcrun notarytool submit \
            go2shell-pro-${{ github.ref_name }}.dmg \
            --keychain-profile "$NOTARY_PROFILE" \
            --wait --timeout 600

          # Staple
          xcrun stapler staple go2shell-pro-${{ github.ref_name }}.dmg

      - name: Create Release Artifacts
        run: |
          zip -r go2shell-pro-${{ github.ref_name }}.zip build/export/Go2ShellPro.app
          shasum -a 256 go2shell-pro-${{ github.ref_name }}.dmg > SHA256SUMS
          shasum -a 256 go2shell-pro-${{ github.ref_name }}.zip >> SHA256SUMS

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            go2shell-pro-${{ github.ref_name }}.dmg
            go2shell-pro-${{ github.ref_name }}.zip
            SHA256SUMS
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

```

#### ExportOptions.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <false/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

#### GitHub Secrets 配置清单
| Secret 名称 | 说明 |
|-------------|------|
| `DEVELOPER_ID_APPLICATION` | 证书名称，如 `Developer ID Application: Your Name (TEAM_ID)` |
| `NOTARYTOOL_PROFILE` | `notarytool` keychain profile 名称（推荐） |

> 说明：Phase 1 不触发 Homebrew 更新；Homebrew 自动更新流程仅在 Phase 2 启用。

### 5.3 Phase 2（Homebrew Cask）

#### Tap 仓库结构
```
homebrew-go2shell-pro/
├── Casks/
│   └── go2shell-pro.rb
├── .github/
│   └── workflows/
│       └── update-cask.yml
└── README.md
```

#### Cask 定义文件
```ruby
# Casks/go2shell-pro.rb
cask "go2shell-pro" do
  version "0.1.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/YOUR_ORG/go2shell-pro/releases/download/v#{version}/go2shell-pro-v#{version}.dmg"
  name "Go2Shell Pro"
  desc "Enhanced macOS Finder to Terminal integration tool"
  homepage "https://github.com/YOUR_ORG/go2shell-pro"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on macos: ">= :sonoma"

  app "Go2ShellPro.app"

  zap trash: [
    "~/Library/Application Support/com.yourorg.go2shell-pro",
    "~/Library/Caches/com.yourorg.go2shell-pro",
    "~/Library/HTTPStorages/com.yourorg.go2shell-pro",
    "~/Library/Preferences/com.yourorg.go2shell-pro.plist",
    "~/Library/WebKit/com.yourorg.go2shell-pro",
  ]

  caveats do
    <<~EOS
      After installation, enable the Finder Extension:
        1. Open System Settings → Privacy & Security → Extensions
        2. Find "Go2Shell Pro" and enable "Finder Extension"
        3. Restart Finder (Cmd+Option+Esc → Finder → Relaunch)
    EOS
  end
end
```

#### 自动更新 Cask 的 GitHub Actions
```yaml
# .github/workflows/update-cask.yml
name: Update Homebrew Cask

on:
  repository_dispatch:
    types: [release]

jobs:
  update-cask:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout tap repository
        uses: actions/checkout@v4

      - name: Download DMG & Compute SHA256
        id: release
        run: |
          VERSION="${{ github.event.client_payload.version }}"
          VERSION_NUM="${VERSION#v}"

          curl -L -o go2shell-pro.dmg \
            "https://github.com/YOUR_ORG/go2shell-pro/releases/download/${VERSION}/go2shell-pro-${VERSION}.dmg"

          SHA256=$(sha256sum go2shell-pro.dmg | cut -d' ' -f1)

          echo "version=$VERSION_NUM" >> $GITHUB_OUTPUT
          echo "sha256=$SHA256" >> $GITHUB_OUTPUT

      - name: Update Cask file
        run: |
          VERSION="${{ steps.release.outputs.version }}"
          SHA256="${{ steps.release.outputs.sha256 }}"

          sed -i "s/version \".*\"/version \"${VERSION}\"/" Casks/go2shell-pro.rb
          sed -i "s/sha256 \".*\"/sha256 \"${SHA256}\"/" Casks/go2shell-pro.rb

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          token: ${{ secrets.TAP_REPO_TOKEN }}
          title: "Update to v${{ steps.release.outputs.version }}"
          body: |
            Automated update for Go2Shell Pro v${{ steps.release.outputs.version }}

            - Version: ${{ steps.release.outputs.version }}
            - SHA256: ${{ steps.release.outputs.sha256 }}
          branch: update-v${{ steps.release.outputs.version }}
          base: main
```

#### 用户安装命令
```bash
# 方式 1：添加 tap 后安装
brew tap YOUR_ORG/go2shell-pro
brew install --cask go2shell-pro

# 方式 2：直接 URL 安装
brew install --cask https://raw.githubusercontent.com/YOUR_ORG/homebrew-go2shell-pro/main/Casks/go2shell-pro.rb

# 卸载
brew uninstall --cask go2shell-pro
brew untap YOUR_ORG/go2shell-pro
```

### 5.4 发布检查清单

| 检查项 | 命令 | 预期结果 |
|--------|------|----------|
| App 签名验证 | `codesign --verify --deep --strict --verbose=2 Go2ShellPro.app` | `valid on disk` |
| App Gatekeeper | `spctl --assess --type execute --verbose Go2ShellPro.app` | `accepted` |
| DMG 公证验证 | `xcrun stapler validate go2shell-pro.dmg` | `The staple and validate action worked!` |
| DMG Gatekeeper | `spctl --assess --type open --context context:primary-signature -v go2shell-pro.dmg` | `accepted` |
| DMG 挂载测试 | 手动双击 DMG | 可正常挂载、拖拽安装 |
| 首次运行测试 | 在全新 VM/机器上运行 | 无 Gatekeeper 弹窗拦截 |
| Homebrew 安装测试（Phase 2） | `brew install --cask YOUR_ORG/go2shell-pro/go2shell-pro` | 安装成功、App 可启动 |

## 6. 里程碑（6 周建议）
- W1：PRD + 信息架构 + 终端适配矩阵。
- W2：Tuist 脚手架 + Finder 扩展最小可用。
- W3：Terminal/iTerm2/Warp 适配 + 错误处理。
- W4：设置页 + 动作模板 + 观测日志。
- W5：联调 + 回归测试 + 内测。
- W6：发布准备（签名/公证/DMG），仅在联调与自测通过后执行。

## 7. 验收标准（Phase 1）
- Finder 中任意目录 1 秒内可打开到目标终端。
- 至少 3 个终端适配通过真实环境验证。
- 多选、文件路径、空格路径、无权限路径均有可预期行为。
- DMG 可安装并在全新机器完成首次运行。

## 8. 实施顺序（建议）
1. 先冻结 `终端兼容矩阵` 与 `Finder 入口优先级`。
2. 按 `交互规格` 搭建最小可用流程（右键单击直开 + 工具栏最小菜单）。
3. 按 `技术设计` 落地 Adapter 分层与失败回退。
4. 在联调与自测通过后，执行签名、公证、DMG 流水线和发布前 Gatekeeper 验证。
