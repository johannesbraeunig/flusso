---
# flusso-8yx9
title: Test harness with first sync test
status: completed
type: task
priority: normal
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:20:02Z
parent: flusso-cp3l
---

## Parent

flusso-cp3l

## What to build

The maintainer can run `make test` to execute a bats suite against the real `flusso` executable without MoneyMoney or network access. Each test runs with a fresh temporary HOME containing a test config. Fake `osascript` and `curl` executables come first on PATH: they serve fixture responses chosen per test and log every invocation (arguments, and the posted body for `curl`). The first test proves the core Transaction Sync path end to end.

## Acceptance criteria

- [x] `make test` runs the suite via bats-core and fails on any failing test
- [x] Each test gets an isolated temporary HOME with its own config; the real ~/.flusso is never touched
- [x] Fake osascript serves fixture plist per AppleScript command (export transactions, export accounts, export categories, set transaction) and logs calls
- [x] Fake curl serves fixture JSON per YNAB endpoint and logs method, path and request body
- [x] Fixture plists are anonymized and include date elements
- [x] Test: an Unsynced Transaction is posted to YNAB (amount in milliunits, import_id, cleared) and then marked as synced with the Sync Category
- [x] README documents how to run the tests (bats-core via Homebrew)

## Summary of Changes

- bats suite under test/, run via `make test`; README has a Development section
- Fake osascript serves MoneyMoney plist fixtures per command and logs calls; for set transaction it resolves the AppleScript statement against its run parameters, so a wrong category is caught (verified by mutation)
- Fake curl serves YNAB fixtures per route and logs method, path and body
- test_helper: isolated HOME, config builder, XML-escaped plist builders, log readers (posted_transactions, marked_as_synced)
- First test: an Unsynced Transaction is posted and marked as synced

Known gap (existing code, not in scope): flusso writes and cleans /tmp/flusso_*.tmp, so tests share /tmp with real runs.
