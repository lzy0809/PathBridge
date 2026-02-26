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
