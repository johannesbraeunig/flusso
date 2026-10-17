---
# flusso-nyi0
title: Pin the uncovered sync behaviour with CLI tests
status: completed
type: task
priority: normal
tags:
    - ready-for-agent
created_at: 2026-10-17T10:21:10Z
updated_at: 2026-10-17T10:22:40Z
parent: flusso-4ctd
---

## Parent

flusso-4ctd: Deepen Transaction Sync into its own module

## What to build

A safety net for the refactor: CLI tests for sync behaviour the suite doesn't cover yet but the refactor will touch. The tests describe how Flusso behaves today and pass against the current code. No production change.

## Acceptance criteria

- [x] A test shows that when the YNAB POST fails for a Transaction Sync mapping, sync prints the YNAB error, marks no transaction as synced, and still syncs the next Account Mapping
- [x] A test shows that a Balance Adjustment YNAB reports as a duplicate (already imported today) is reported as skipped and not counted in the summary
- [x] A test shows the final summary totals are correct across several Account Mappings that mix Transaction Sync and Balance Sync (transactions synced plus the Balance Adjustment note)
- [x] Tests drive the `flusso` CLI only, through the existing fake `osascript` and `curl`, and reuse the fixture builders in the test helper
- [x] The full bats suite passes with no change to `flusso`

## Summary of Changes

Added four CLI tests to sync.bats: a failed YNAB POST across two Account Mappings (errors reported, nothing marked as synced, both mappings attempted), a Balance Adjustment already imported today, and the summary totals for mixed Transaction Sync and Balance Sync mappings, both live and in a dry run. No production change; suite is 56/56 green.
