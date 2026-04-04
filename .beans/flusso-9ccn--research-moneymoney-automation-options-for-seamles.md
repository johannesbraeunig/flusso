---
# flusso-9ccn
title: Research MoneyMoney automation options for seamless sync
status: completed
type: task
priority: normal
created_at: 2026-04-05T16:04:12Z
updated_at: 2026-04-05T16:05:01Z
---

Research AppleScript API, URL schemes, bundleIdentifier, fswatch/launchd, and Shortcuts/Automator approaches for automating the MoneyMoney to YNAB sync workflow.

## Summary of Changes

Completed research on all five automation options. Key finding: MoneyMoney has a full AppleScript API that supports programmatic export of transactions with custom Lua extension formats. This enables a single-command sync workflow with no manual export step. URL schemes are not supported. bundleIdentifier enables a 'Send Transactions To' menu but requires a .app bundle. Folder watching (fswatch/launchd) is unnecessary given AppleScript. macOS Shortcuts can wrap the AppleScript flow for one-click triggering.
