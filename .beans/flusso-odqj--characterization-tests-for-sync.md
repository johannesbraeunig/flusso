---
# flusso-odqj
title: Characterization tests for sync
status: todo
type: task
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:15:10Z
parent: flusso-cp3l
blocked_by:
    - flusso-8yx9
---

## Parent

flusso-cp3l

## What to build

The current behaviour of `flusso sync` is pinned by tests at the CLI seam, so the following refactors can be verified without changing any test. The tests run against today's code and must pass before any refactor starts.

## Acceptance criteria

- [ ] Synced Transactions are neither posted nor marked again
- [ ] `--dry-run` posts nothing, marks nothing, and lists the would-be transactions
- [ ] `--account` limits the sync to one Account Mapping
- [ ] A MoneyMoney export returning a single transaction object (not an array) is handled
- [ ] A failed MoneyMoney export prints the error, skips that Account Mapping and continues with the next
- [ ] Pending Transactions are skipped without include_pending / `--include-pending`
- [ ] With the flag, Pending Transactions are posted as uncleared without import_id and are never marked as synced
- [ ] A Pending Transaction already in YNAB (same date and amount, no import_id) is not posted again; with two identical Pending Transactions and one in YNAB, exactly one is posted
- [ ] Balance Sync posts a Balance Adjustment for the difference, or reports the balance as up to date
- [ ] Tests assert only on exit status, output and the fakes' call logs
