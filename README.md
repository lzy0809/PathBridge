# PathBridge

PathBridge 是一个 macOS Finder 扩展工具，用于从 Finder 快速在终端中打开目录。

## 当前状态

- 已完成文档规划与技术方案
- 已初始化 Tuist 工程骨架（App + Finder Extension + Core + Adapters + Shared）
- 已实现最小可用链路：Finder 菜单触发后打开系统 Terminal
- 已接入扩展到主应用的请求通道（DistributedNotification），并保留扩展直开兜底

## 本地开发

```bash
tuist install
tuist generate
open PathBridge.xcworkspace
```

## 联调验证

1. 运行 `PathBridgeApp`。
2. 在系统设置中启用 Finder 扩展 `PathBridge Finder Extension`。
3. 在 Finder 中右键目录，点击 `Open in Terminal`，确认能打开到目标目录。

## Finder 扩展入口排查

如果系统设置里看不到 `PathBridge Finder Extension`，按下面顺序排查：

1. 在 Xcode 的 `PathBridgeApp` 和 `PathBridgeFinderExtension` 两个 target 里都选择同一个 `Team`（签名证书）。
2. 清理并重新构建后运行 App（`Shift + Cmd + K`，再 `Cmd + R`）。
3. 检查扩展是否被系统注册：

```bash
pluginkit -m -A -D -p com.apple.FinderSync | grep -i pathbridge
```

4. 若未注册，手动注册后重启 Finder：

```bash
pluginkit -a /Applications/PathBridgeApp.app/Contents/PlugIns/PathBridgeFinderExtension.appex
killall Finder
```

说明：Finder Sync 扩展需要有效开发者签名；`adhoc` 签名通常不会出现在系统扩展列表中。

## 生成 DMG

快速打包（不签名）：

```bash
scripts/release/make_dmg.sh
```

签名、公证、DMG 产物说明见：

- `docs/signing-and-dmg.md`
