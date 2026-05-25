# Testing Guide

This project has no traditional unit/integration test suite. Features are tested via simulator automation.

## Prerequisites

- Xcode installed (check `versions.json` for required version)
- iOS Simulator booted (`xcrun simctl boot <UDID>`)
- [idb](https://fbidb.io/) installed (`brew install idb-companion`) — used for reliable touch input
- App built and installed on simulator (see [CLAUDE.md](../CLAUDE.md) for build instructions)

## Build for Simulator

1. **Generate the Xcode project** (once, or after BUILD file changes):
   ```bash
   python3 build-system/Make/Make.py \
       --cacheDir="$HOME/telegram-bazel-cache" \
       --overrideXcodeVersion \
       generateProject \
       --configurationPath=build-system/configuration.json \
       --xcodeManagedCodesigning
   ```

2. **Fix the disk cache path** (the generator writes a relative path):
   ```bash
   sed -i '' "s|--disk_cache=/telegram-bazel-cache|--disk_cache=$HOME/telegram-bazel-cache|" xcodeproj.bazelrc
   ```

3. **Build**:
   ```bash
   xcodebuild -project Telegram/Swiftgram.xcodeproj \
       -scheme Swiftgram \
       -configuration Debug \
       -sdk iphonesimulator \
       -destination 'id=<SIMULATOR_UDID>' \
       build
   ```

4. **Install on simulator**:
   ```bash
   APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData/Swiftgram-*/Build/Products/Debug-iphonesimulator -name 'Swiftgram.app' -path '*/bin/Telegram/*' | head -1)"
   xcrun simctl install <SIMULATOR_UDID> "$APP_PATH"
   ```

## Test Mode Launch Arguments

The app supports launch arguments for testing features that normally require a logged-in account:

| Argument | Effect |
|----------|--------|
| `--test-focus-mode` | Bypasses login, sets timeout to 0, presents a test tab bar with search activated. Verifies focus mode UI shows search with tab bar visible. |

### Running a test

```bash
# Launch with test argument
xcrun simctl launch <SIMULATOR_UDID> se.derg.FocusGram -- --test-focus-mode

# Capture logs (print output from the app)
xcrun simctl launch --console-pty <SIMULATOR_UDID> se.derg.FocusGram -- --test-focus-mode

# Take a screenshot for visual verification
xcrun simctl io <SIMULATOR_UDID> screenshot /tmp/test-result.png
```

### Expected output for `--test-focus-mode`

**Logs:**
```
[FocusMode] TEST MODE: setting pendingFocusModeCheck=true, timeout=0
[FocusMode] pendingFocusModeCheck triggered, focusModeEnabled=true
[FocusMode] activateFocusMode() called
[FocusMode] TEST MODE: bypassing authorizedContext, calling test UI
[FocusMode] TEST: Search activated. Tab bar visible: true
[FocusMode] TEST PASSED: Focus mode UI is showing with tab bar visible
```

**Screenshot:** Search bar active at top, tab bar visible at bottom with Chats/Contacts/Settings tabs.

## Telegram Test DC (for testing with a real account)

Telegram provides test data centers that accept synthetic phone numbers. To use:

1. On the phone entry screen, enter `0000000000` and tap Continue — this activates test DC mode (Swiftgram shortcut at `AuthorizationSequencePhoneEntryController.swift:412`)
2. On the new phone entry screen, enter a test number: `+999 66 XNNNN` where X is DC number (1–3)
3. Verification code is X repeated 5 times (e.g., DC 2 → code `22222`)

**Note:** Test DCs may be unreachable. If the "Start Messaging" button stays disabled after switching to test mode, the test servers are down.

## Simulator Interaction with idb

For automated UI testing, use `idb` for touch input (more reliable than coordinate-based tools):

```bash
# Tap at a point
idb ui tap <x> <y> --udid <SIMULATOR_UDID>

# Type text into focused field
idb ui text "hello" --udid <SIMULATOR_UDID>

# Get accessibility tree (find element positions)
idb ui describe-all --udid <SIMULATOR_UDID>
```

## Adding New Test Modes

To add a testable feature:

1. Add a launch argument check in the relevant code:
   ```swift
   if ProcessInfo.processInfo.arguments.contains("--test-my-feature") {
       // bypass dependencies, create test UI
   }
   ```

2. Document the argument in the table above.

3. Ensure the test mode:
   - Prints `[FeatureName] TEST PASSED` or `TEST FAILED` to stdout
   - Can be verified via screenshot
   - Cleans up after itself (doesn't persist state)
