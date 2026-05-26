# exteraGram Enhanced

基于 exteraGram (Telegram iOS) 的增强定制版。集成 Swiftgram-Pro、Afon、SonicX 等主流分支特性，额外加入按浏览量排序、反撤销、幽灵模式、Premium 伪装等实用功能。

> ⚠️ **无有效 Apple 开发者签名**，需通过 LiveContainer / SideStore 侧载安装。构建使用假签名 (fake codesigning)，iCloud 和 Siri 已禁用以避免崩溃。

---

## 功能介绍

| 功能 | 说明 |
|------|------|
| **反撤销 / 防撤回** | 对方撤回消息后仍可查看内容 |
| **幽灵模式** | 已读消息但不发送已读回执 |
| **Premium 伪装** | 本地解锁 Premium 专属表情、贴纸、上限 |
| **赞助消息拦截** | 屏蔽公共频道底部广告 |
| **专注模式** | 仅显示指定联系人通知，其余折叠 |
| **禁止转发绕过** | 突破对方设置的禁止转发限制 |
| **无限置顶** | 解除置顶消息数量限制 |
| **匿名模式** | 群组中隐藏本人昵称和头像 |
| **媒体持久化存储** | 任意媒体直接保存到系统相册 |
| **屏幕录制保护绕过** | 私密聊天中截屏/录屏不触发警告 |
| **上传加速** | TCP 拥塞控制优化，大文件上传提升约 30% |
| **按浏览量排序** | 共享媒体按浏览量降序排列，带自动加载进度 |
| **Swiftgram-Pro 解锁** | 硬编码解锁所有 Pro 付费功能 |

完整功能说明见 [FEATURES.md](./FEATURES.md)。

---

## 构建 (GitHub Actions)

推送 `merged-all` 分支自动触发 CI 构建：

```yaml
# .github/workflows/build.yml
on:
  push:
    branches: [merged-all]
  workflow_dispatch:
```

产物：`Telegram.ipa` + `Telegram.DSYMs.zip`，自动发布到 GitHub Releases。

也可在 `bookerlevitreobq/exteraGram` 仓库手动触发 `workflow_dispatch`。

---

## 本地构建 (macOS + Xcode 26.4+)

```bash
# 导入假签名证书
python3 build-system/Make/ImportCertificates.py \
  --path build-system/fake-codesigning/certs

# 编译
python3 -u build-system/Make/Make.py \
  --overrideXcodeVersion \
  build \
  --configurationPath="build-system/appstore-configuration.json" \
  --codesigningInformationPath=build-system/fake-codesigning \
  --configuration=release_arm64 \
  --buildNumber=1
```

IPA 输出在 `bazel-bin/Telegram/*.ipa`。

---

## 分支说明

| 分支 | 说明 |
|------|------|
| `merged-all`（默认） | 完整功能合并分支，用于 CI 构建 |
| `clean-branch` | 清理历史后的分支，仅含本仓库专属提交 |

---

## 致谢

- [exteraGram](https://github.com/exteraGram)
- [Swiftgram](https://github.com/Swiftgram)
- [Afon](https://github.com/gfgfgfgf-crypto/Afon)
- [SonicX](https://github.com/SonicX)
- [Telegram iOS](https://github.com/TelegramMessenger)

# Telegram iOS Source Code Compilation Guide

We welcome all developers to use our API and source code to create applications on our platform.
There are several things we require from **all developers** for the moment.

# Creating your Telegram Application

1. [**Obtain your own api_id**](https://core.telegram.org/api/obtaining_api_id) for your application.
2. Please **do not** use the name Telegram for your app — or make sure your users understand that it is unofficial.
3. Kindly **do not** use our standard logo (white paper plane in a blue circle) as your app's logo.
3. Please study our [**security guidelines**](https://core.telegram.org/mtproto/security_guidelines) and take good care of your users' data and privacy.
4. Please remember to publish **your** code too in order to comply with the licences.

# Quick Compilation Guide

## Get the Code

```
git clone --recursive -j8 https://github.com/Swiftgram/Telegram-iOS.git
```

## Setup Xcode

Install Xcode (directly from https://developer.apple.com/download/applications or using the App Store).

## Adjust Configuration

1. Generate a random identifier:
```
openssl rand -hex 8
```
2. Create a new Xcode project. Use `Swiftgram` as the Product Name. Use `org.{identifier from step 1}` as the Organization Identifier.
3. Open `Keychain Access` and navigate to `Certificates`. Locate `Apple Development: your@email.address (XXXXXXXXXX)` and double tap the certificate. Under `Details`, locate `Organizational Unit`. This is the Team ID.
4. Edit `build-system/template_minimal_development_configuration.json`. Use data from the previous steps.

## Generate an Xcode project

```
python3 build-system/Make/Make.py \
    --cacheDir="$HOME/telegram-bazel-cache" \
    generateProject \
    --configurationPath=build-system/template_minimal_development_configuration.json \
    --xcodeManagedCodesigning
```

# Advanced Compilation Guide

## Xcode

1. Copy and edit `build-system/appstore-configuration.json`.
2. Copy `build-system/fake-codesigning`. Create and download provisioning profiles, using the `profiles` folder as a reference for the entitlements.
3. Generate an Xcode project:
```
python3 build-system/Make/Make.py \
    --cacheDir="$HOME/telegram-bazel-cache" \
    generateProject \
    --configurationPath=configuration_from_step_1.json \
    --codesigningInformationPath=directory_from_step_2
```

## IPA

1. Repeat the steps from the previous section. Use distribution provisioning profiles.
2. Run:
```
python3 build-system/Make/Make.py \
    --cacheDir="$HOME/telegram-bazel-cache" \
    build \
    --configurationPath=...see previous section... \
    --codesigningInformationPath=...see previous section... \
    --buildNumber=100001 \
    --configuration=release_arm64
```

# FAQ

## Xcode is stuck at "build-request.json not updated yet"

Occasionally, you might observe the following message in your build log:
```
"/Users/xxx/Library/Developer/Xcode/DerivedData/Telegram-xxx/Build/Intermediates.noindex/XCBuildData/xxx.xcbuilddata/build-request.json" not updated yet, waiting...
```

Should this occur, simply cancel the ongoing build and initiate a new one.

## Telegram_xcodeproj: no such package 

Following a system restart, the auto-generated Xcode project might encounter a build failure accompanied by this error:
```
ERROR: Skipping '@rules_xcodeproj_generated//generator/Telegram/Telegram_xcodeproj:Telegram_xcodeproj': no such package '@rules_xcodeproj_generated//generator/Telegram/Telegram_xcodeproj': BUILD file not found in directory 'generator/Telegram/Telegram_xcodeproj' of external repository @rules_xcodeproj_generated. Add a BUILD file to a directory to mark it as a package.
```

If you encounter this issue, re-run the project generation steps in the README.


# Tips

## Codesigning is not required for simulator-only builds

Add `--disableProvisioningProfiles`:
```
python3 build-system/Make/Make.py \
    --cacheDir="$HOME/telegram-bazel-cache" \
    generateProject \
    --configurationPath=path-to-configuration.json \
    --codesigningInformationPath=path-to-provisioning-data \
    --disableProvisioningProfiles
```

## Versions

Each release is built using a specific Xcode version (see `versions.json`). The helper script checks the versions of the installed software and reports an error if they don't match the ones specified in `versions.json`. It is possible to bypass these checks:

```
python3 build-system/Make/Make.py --overrideXcodeVersion build ... # Don't check the version of Xcode
```
