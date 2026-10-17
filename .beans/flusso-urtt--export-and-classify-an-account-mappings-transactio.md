---
# flusso-urtt
title: Export and classify an Account Mapping's transactions in one place
status: completed
type: task
priority: normal
tags:
    - ready-for-agent
created_at: 2026-10-17T10:21:11Z
updated_at: 2026-10-17T10:24:08Z
parent: flusso-4ctd
blocked_by:
    - flusso-nyi0
---

## Parent

flusso-4ctd: Deepen Transaction Sync into its own module

## What to build

One module that exports a Transaction Sync mapping's transactions from MoneyMoney and classifies them into Synced, Unsynced and Pending Transactions. It owns the policy for what a MoneyMoney export failure means:

- invalid input (account number or start date) stops the run
- a failed or unparseable export comes back to the caller as a failure, with its reason and its kind (export failed / couldn't parse)

Sync turns those failures into its existing messages and moves on to the next Account Mapping. Status turns them into zero counts. The exit-code handling status keeps today goes away. AppleScript access stays in the `mm_*` functions. Users see no change.

## Acceptance criteria

- [x] One module exports and classifies a mapping's transactions and owns the export-failure policy
- [x] Sync and status both use it; neither maps MoneyMoney export exit codes itself
- [x] Sync still prints the existing "Could not export from MoneyMoney" hint and the parse error, then continues with the next Account Mapping
- [x] Status still shows "0 synced, 0 unsynced" for a mapping whose export fails or can't be parsed, and stops on invalid input
- [x] The full bats suite passes unmodified

## Summary of Changes

Added `export_classified_transactions`: it exports a MoneyMoney Account since a start date and classifies the transactions into `CLASSIFIED_TRANSACTIONS`. It stops the run on invalid input, and on a failed or unparseable export it returns `MM_EXPORT_FAILED` / `MM_PARSE_FAILED` with the reason in `EXPORT_PROBLEM`. It reports through variables rather than stdout so that `die` runs in the main shell; callers must call it directly, not in `$(...)`. Sync and status no longer map export exit codes themselves. Suite 56/56 green.
