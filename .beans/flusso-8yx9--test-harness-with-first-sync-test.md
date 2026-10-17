---
# flusso-8yx9
title: Test harness with first sync test
status: todo
type: task
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:15:10Z
parent: flusso-cp3l
---

## Parent

flusso-cp3l

## What to build

The maintainer can run `make test` to execute a bats suite against the real `flusso` executable without MoneyMoney or network access. Each test runs with a fresh temporary HOME containing a test config. Fake `osascript` and `curl` executables come first on PATH: they serve fixture responses chosen per test and log every invocation (arguments, and the posted body for `curl`). The first test proves the core Transaction Sync path end to end.

## Acceptance criteria

- [ ] `make test` runs the suite via bats-core and fails on any failing test
- [ ] Each test gets an isolated temporary HOME with its own config; the real ~/.flusso is never touched
- [ ] Fake osascript serves fixture plist per AppleScript command (export transactions, export accounts, export categories, set transaction) and logs calls
- [ ] Fake curl serves fixture JSON per YNAB endpoint and logs method, path and request body
- [ ] Fixture plists are anonymized and include date elements
- [ ] Test: an Unsynced Transaction is posted to YNAB (amount in milliunits, import_id, cleared) and then marked as synced with the Sync Category
- [ ] README documents how to run the tests (bats-core via Homebrew)
