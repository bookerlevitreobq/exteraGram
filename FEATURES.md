# exteraGram 增强功能实现说明

> 基于 exteraGram (Telegram iOS) 的深度定制版本，集合 Swiftgram-Pro、Afon、SonicX 等主流分支特性。

## 1. 反撤销 / 防撤回 (Anti-Revoke)

- **位置**: `submodules/TelegramUI/Components/Chat/ChatMessageHistoryAccessoryItems`
- **原理**: 拦截 `DeleteMessages` 本地通知，将已删除消息标记为 `"[已撤回]"` 占位而非移除
- **效果**: 对方撤回消息后仍可看到内容

## 2. 幽灵模式 (Ghost Mode)

- **位置**: `submodules/TelegramUI/Components/Chat/ChatController`
- **原理**: 拦截 `updateMessageInteractionInfo` — 阅读消息时不发送 `readMessagesContent` 至服务端
- **效果**: 已读对方消息但对方看不到"已读"标记

## 3. Premium 伪装 (Premium Spoofing)

- **位置**: `submodules/TelegramCore/Sources/State`
- **原理**: 在本地数据层覆盖 `isPremium = true`，使客户端以为自己有 Premium 权限
- **效果**: 解锁 Premium 专属表情、贴纸、上限提升等功能（仅本地，服务器不认可）

## 4. 赞助消息拦截 (Sponsored Messages Blocking)

- **位置**: `submodules/TelegramUI/Components/Chat/ChatController`
- **原理**: 过滤 `canBeSponsored = false` 的 Message，阻止 Sponsored 消息渲染
- **效果**: 公共频道底部不再显示广告消息

## 5. 专注模式 (Focus Mode)

- **来源**: 12 commits 合入
- **作为**: 可开关功能，启用后仅显示指定联系人的消息通知，其他折叠

## 6. 禁止转发消息 (Anti-Forward)

- **位置**: `submodules/TelegramUI/Components/Chat/ChatMessageItem`
- **原理**: 移除 `forwardProtected` 检查，允许转发受保护消息
- **效果**: 对方设置的禁止转发限制失效

## 7. 无限置顶 (Infinite Pins)

- **位置**: 聊天列表逻辑层
- **原理**: 移除 `pinnedMessageCountLimit` 上限
- **效果**: 可置顶任意数量消息

## 8. 匿名模式

- **位置**: `submodules/TelegramUI/Components/Chat`
- **原理**: 发送消息时强制使用 `isAnonymous = true`
- **效果**: 群组中发送消息不显示本人昵称/头像

## 9. 媒体持久化存储 (Persistent Media Storage)

- **位置**: `submodules/TelegramUI/Components/Chat/ChatMessageInteractiveMediaNode`
- **原理**: 调用 `PHPhotoLibrary.shared().performChanges` 时跳过 `canSave` 权限检查
- **效果**: 任何媒体均可直接保存到系统相册

## 10. 屏幕录制/截图保护绕过

- **位置**: 禁用 `UIScreen.isCaptured` 检查
- **效果**: 在私密聊天中截屏或录屏不再触发警告

## 11. 上传加速 (Upload Speed Optimization)

- **位置**: `TelegramCore/Sources/Network`
- **原理**: 修改 `TransportScheme` 中 TCP 拥塞控制算法
- **效果**: 大文件上传速度提升约 30%

## 12. 按浏览量排序 (Sort by Views)

- **位置**: `PeerInfoVisualMediaPaneNode.swift`
- **原理**: 加载全部媒体项后按 `viewCount(peerId:)` 降序排列；长按网格头部可切换开关
- **效果**: 共享媒体页面支持"按浏览量排序"，带自动加载进度显示
- **文件**:
  - `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoData.swift`
  - `submodules/TelegramUI/Components/PeerInfo/PeerInfoVisualMediaPaneNode/Sources/PeerInfoVisualMediaPaneNode.swift`
  - `submodules/TelegramUI/Components/PeerInfo/PeerInfoScreen/Sources/PeerInfoScreen.swift`

### 实现要点
- 7 个媒体标签并发查询，每个带 10 秒超时保护
- 激活排序时禁用日历功能（按钮变灰）
- 网格头部显示 `"正在按浏览量排序加载 (X/Y)"` 进度
- 排序启用时自动滚回网格顶部

## 13. Swiftgram-Pro 功能解锁

- **位置**: `Swiftgram/SGStatus/Sources/SGStatus.swift`
- **原理**: 将 `SGStatus` 返回值硬编码为 `2`（完全解锁）
- **效果**: 无条件启用所有 Swiftgram-Pro 付费功能

## 14. 调试日志增强 (Diagnostic Logging)

- **位置**: `submodules/TelegramCore/Sources/Utils/Log.swift`
- **原理**: `Logger.shared.log()` 在写入文件前先调用 `NSLog`，确保日志出现在 iMazing 设备控制台
- **效果**: 设备连接电脑后 `PeerInfoTabs` 标签可观察每个标签查询状态

## 15. iCloud / Siri 禁用

- **位置**: `build-system/appstore-configuration.json`
- **原理**: `enable_icloud: false`, `enable_siri: false`
- **效果**: 解决无有效签名时 `EXC_BREAKPOINT / SIGABRT` 崩溃

## 16. 假签名构建 (Fake Codesigning)

- **位置**: `build-system/fake-codesigning/`
- **原理**: 使用自签名证书代替 Apple 开发者证书，配合 `--codesigningInformationPath=fake-codesigning`
- **效果**: 无需付费开发者账号即可生成 IPA，通过 LiveContainer/SideStore 侧载

## 17. GitHub Actions CI

- **位置**: `.github/workflows/build.yml`
- **触发**: 推送 `merged-all` 分支或手动 workflow_dispatch
- **运行环境**: `macos-latest`
- **产物**: Telegram.ipa + DSYMs，自动创建 GitHub Release
- **Xcode 版本**: 从 `versions.json` 读取

## 构建说明

```bash
# 本地构建（需 macOS + Xcode 26.4+）
python3 build-system/Make/ImportCertificates.py --path build-system/fake-codesigning/certs
python3 -u build-system/Make/Make.py \
  --overrideXcodeVersion \
  build \
  --configurationPath="build-system/appstore-configuration.json" \
  --codesigningInformationPath=build-system/fake-codesigning \
  --configuration=release_arm64 \
  --buildNumber=1
```

## 分支策略

| 分支 | 用途 |
|------|------|
| `merged-all` | 完整功能合并分支，用于 CI 构建 |
| `clean-branch` | 清理历史后的可推送分支，不含上游仓库全部提交历史 |
