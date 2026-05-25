# Focus Mode — Product Spec

## Problem
When opening Telegram with a specific intent (e.g., send someone a message), unread chats and open conversations hijack attention. The user forgets their original purpose and gets pulled into reactive messaging.

## Solution
A **focus screen** that appears when the app has been in the background for longer than a configurable timeout (default: 5 minutes). The focus screen shows a clean search interface — no unread counts, no chat previews, no distractions. Just a search bar to find the person/group you came to message.

## Core Mechanics

### Trigger
- Track the timestamp when the app leaves foreground (`willResignActive` / `didEnterBackground`).
- On return to foreground (`willEnterForeground`), if elapsed time > threshold → show focus screen.
- If elapsed time ≤ threshold → resume normally (session continuity).
- Threshold is configurable in settings. Default: 5 minutes.

### Focus Screen
- A dedicated **Focus tab** in the tab bar (first position).
- The Focus tab shows search UI immediately — no chat list underneath, no transition animation.
- Search results show **avatar + name only** (no last message, no timestamps, no unread badges).
- The top peers avatar carousel is hidden on the Focus tab.
- Tapping a result opens the chat normally — no further restrictions inside the chat.
- Other tabs (Chats, Settings, etc.) remain accessible via the tab bar. No tabs are hidden or disabled.
- The Focus tab is the default selected tab when focus mode is enabled.

### After Task Completion
- No special behavior. Once the user is past the focus screen and inside a chat, Telegram works normally.
- The focus screen is an **entry gate**, not a persistent mode.

### Bypasses
- Tapping a notification opens the relevant chat directly, bypassing the focus screen.
- Returning to the app within the timeout threshold resumes normally.

### State Preservation
- When the focus screen activates, the previous navigation state (open chat, selected tab) is preserved in the background. Tapping the Chats tab returns to where the user was. (This behavior may be revisited after real-world usage.)

## Scope

### In scope (MVP)
- Foreground timestamp tracking
- Dedicated Focus tab with permanent search UI (first tab)
- Configurable timeout in settings
- Notification tap bypass
- iPhone only
- On by default

### Out of scope (future)
- Pinned chats as quick-access on focus screen
- iPad split view considerations
- Hiding/disabling tabs during focus screen
- In-chat message hiding
- Per-account settings (multi-account)
