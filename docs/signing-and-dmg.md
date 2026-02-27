# PathBridge 签名与 DMG 打包

本文档用于本地发布 PathBridge 的可安装 DMG（支持可选签名与公证）。

## 1. 前置条件

- 已安装 Xcode / Command Line Tools
- 已安装 Tuist（脚本默认会执行 `tuist generate`）
- 可选：Developer ID 证书（用于对外分发）
- 可选：`notarytool` keychain profile（用于 Apple 公证）

## 2. 一键打包（不签名）

```bash
scripts/release/make_dmg.sh
```

产物目录：

- `build/release/app/PathBridge.app`
- `build/release/dmg/PathBridge-<timestamp>-<sha>.dmg`
- `build/release/dmg/PathBridge-<...>.dmg.sha256`

## 3. 签名 + 打包

```bash
DEVELOPER_ID_APPLICATION="Developer ID Application: YOUR_NAME (TEAMID)" \
scripts/release/make_dmg.sh
```

## 4. 签名 + 公证 + Staple

先配置 keychain profile（只需一次）：

```bash
xcrun notarytool store-credentials "pathbridge-notary" \
  --apple-id "<apple-id>" \
  --team-id "<team-id>" \
  --password "<app-specific-password>"
```

执行完整流程：

```bash
DEVELOPER_ID_APPLICATION="Developer ID Application: YOUR_NAME (TEAMID)" \
NOTARYTOOL_PROFILE="pathbridge-notary" \
scripts/release/make_dmg.sh
```

## 5. 常用环境变量

- `SCHEME`：默认 `PathBridgeApp`
- `WORKSPACE_PATH`：默认 `PathBridge.xcworkspace`
- `VERSION_TAG`：自定义 DMG 版本名后缀
- `SKIP_TUIST_GENERATE=1`：跳过 `tuist generate`
- `ALLOW_UNSIGNED_ARCHIVE=1`：Archive 阶段禁用签名（仅本地验证）

## 6. 发布前验证

```bash
codesign --verify --deep --strict --verbose=2 build/release/app/PathBridge.app
spctl --assess --type open --context context:primary-signature -v build/release/dmg/*.dmg
```

