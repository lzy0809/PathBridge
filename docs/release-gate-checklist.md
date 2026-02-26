# 发布门禁检查清单（Phase 1 -> 外部发布）

## A. 启动发布前（必须全部通过）
- [ ] 功能冻结：PRD 范围内功能全部完成，无 P0/P1 阻塞缺陷。
- [ ] 联调通过：Finder 扩展、Host App、TerminalAdapters 全链路通过。
- [ ] 回归通过：核心场景（单选、多选、文件/目录、失败回退）通过。
- [ ] 自测通过：至少两台机器（建议 Intel + Apple Silicon）验证通过。

## B. 打包与签名
- [ ] `tuist install && tuist generate` 成功。
- [ ] `xcodebuild archive` 成功，产出 `.xcarchive`。
- [ ] `.app` 使用 Developer ID 签名（含 Hardened Runtime）。
- [ ] 产出 `.dmg` 与 `.zip`，并生成 `SHA256SUMS`。

## C. 公证与验证
- [ ] `notarytool submit` 成功（推荐 `--keychain-profile`）。
- [ ] `xcrun stapler staple` 成功。
- [ ] `codesign --verify --deep --strict --verbose=2` 通过。
- [ ] `spctl --assess --type execute --verbose` 通过。
- [ ] `xcrun stapler validate` 通过。

## D. 发布后验证
- [ ] 在全新环境安装 DMG 并首次启动成功。
- [ ] Finder 扩展可启用且可正常触发打开终端。
- [ ] 发布产物与版本号、校验值一致。

## E. Phase 2（后置）
- [ ] Homebrew Tap/Cask 更新与安装验证通过。
