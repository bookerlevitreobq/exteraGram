# 52sanmao/Telegram-iOS Custom Build

Based on [Swiftgram/Telegram-iOS](https://github.com/Swiftgram/Telegram-iOS), with GitHub Actions CI builds enabled and a new feature added.

## Download

Latest release: **Telegram 12.6.2 (32767)**

- IPA: https://github.com/52sanmao/Telegram-iOS/releases/latest
- DSYM: https://github.com/52sanmao/Telegram-iOS/releases/latest

## Feature Changes

### Sort Shared Media by Views

Added a toggle in **Peer Info > Media gallery context menu** to sort shared media by **view count** (descending) instead of the default **date** sorting. Works in channels and groups where view counts are available.

- Sorting state is persisted per-pane and survives tab switches
- Sparse loading behavior is preserved (no full preload on sort change)
- Falls back to date sorting gracefully when view data is unavailable

Files changed:
- `PeerInfoScreenDisplayMediaGalleryContextMenu.swift`
- `PeerInfoVisualMediaPaneNode.swift`

## CI / Build Compatibility

The following changes enable GitHub Actions CI builds on hosted macOS runners, without affecting the main Xcode-based build:

| Change | Purpose |
|--------|---------|
| Use latest macOS runner | Fix deprecated `macos-12` runner |
| Fall back to default Xcode path | Handle missing versioned Xcode on hosted runners |
| Allow Xcode version override | Let CI skip strict version pinning |
| Add `sg_config` to appstore config | Fix missing Swiftgram config reference |
| Use legacy app icon | Avoid iOS 26 icon APIs unavailable in CI SDK |
| Guard iOS 26 windowing API | `#if compiler(>=6.2)` around `NativeWindowHostView` |
| Stub dav1d vcs header | Provide missing `dav1d_version.h` in hosted builds |
| Guard glass effect APIs | `#if compiler(>=6.2)` around `GlassBackgroundComponent` |
| Guard native slider tick config | `#if compiler(>=6.2)` around `SliderComponent` |
| Guard passkey updater APIs | `#if compiler(>=6.2)` around `PasskeysScreen` |
| Guard context glass corner APIs | `#if compiler(>=6.2)` around `ContextControllerActionsStackNode` |
| Fix Sendable caption crossing | Isolate caption state in `AttachmentController` to avoid concurrency warnings |
| Remove unused picker binding | Clean up dead code in AI compose path |
| Expose PeerInfo sorting state | `public private(set)` for cross-target menu access |
| Guard continued background task APIs | `#if compiler(>=6.2)` around `BGContinuedProcessingTask` in `SharedWakeupManager` |
| Fix artifact collection path | Match `bazel-bin/Telegram/*.ipa` instead of stale `bazel-out` path |
| Grant release permissions | Add `permissions: contents: write` for `actions/create-release` |

## How It Builds

```
GitHub Actions (workflow_dispatch)
  -> macOS-15-arm64 runner
  -> Bazel build (release_arm64)
  -> Swiftgram.ipa + dSYMs
  -> GitHub Release with downloadable artifacts
```

Trigger manually via the Actions tab or:
```bash
gh workflow run CI --repo 52sanmao/Telegram-iOS --ref master
```

## Upstream

Synced with [Swiftgram/Telegram-iOS](https://github.com/Swiftgram/Telegram-iOS) master (`02fac48ed1`).

To update:
```bash
git remote add upstream https://github.com/Swiftgram/Telegram-iOS.git
git fetch upstream
git rebase upstream/master
```
