---
# flusso-odqj
title: Characterization tests for sync
status: completed
type: task
priority: normal
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:23:35Z
parent: flusso-cp3l
blocked_by:
    - flusso-8yx9
---

## Parent

flusso-cp3l

## What to build

The current behaviour of `flusso sync` is pinned by tests at the CLI seam, so the following refactors can be verified without changing any test. The tests run against today's code and must pass before any refactor starts.

## Acceptance criteria

- [x] Synced Transactions are neither posted nor marked again
- [x] `--dry-run` posts nothing, marks nothing, and lists the would-be transactions
- [x] `--account` limits the sync to one Account Mapping
- [x] A MoneyMoney export returning a single transaction object (not an array) is handled
- [x] A failed MoneyMoney export prints the error, skips that Account Mapping and continues with the next
- [x] Pending Transactions are skipped without include_pending / `--include-pending`
- [x] With the flag, Pending Transactions are posted as uncleared without import_id and are never marked as synced
- [x] A Pending Transaction already in YNAB (same date and amount, no import_id) is not posted again; with two identical Pending Transactions and one in YNAB, exactly one is posted
- [x] Balance Sync posts a Balance Adjustment for the difference, or reports the balance as up to date
- [x] Tests assert only on exit status, output and the fakes' call logs

## Summary of Changes

14 bats tests in test/sync.bats pin the current behaviour of `flusso sync`: Unsynced vs Synced Transactions, dry run, --account, single-object export, failed export per Account Mapping, Pending Transactions (default skip, flag and config, uncleared without import_id, never marked, multiset dedup against YNAB, since_date lookup), and Balance Sync (adjustment posted, up to date). Each was verified to fail under a targeted mutation of flusso. Helpers gained per-account export fixtures, account export fixtures, YNAB balance/transactions routes and a shared plist prolog.
