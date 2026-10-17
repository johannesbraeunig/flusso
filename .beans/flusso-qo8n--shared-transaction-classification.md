---
# flusso-qo8n
title: Shared transaction classification
status: completed
type: task
priority: normal
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:38:32Z
parent: flusso-cp3l
blocked_by:
    - flusso-9via
---

## Parent

flusso-cp3l

## What to build

One classification splits a MoneyMoney Account's transactions into Synced, Unsynced and Pending Transactions (as defined in GLOSSARY.md), given the Sync Category. `sync` posts the Unsynced group (plus new Pending Transactions when enabled), `status` counts Synced and Unsynced, and the pending dedup against YNAB consumes the Pending group. The rules for "is this synced?" then live in one place, which unblocks flusso-qgkr.

## Acceptance criteria

- [x] A single classification is the only place that decides Synced vs Unsynced vs Pending
- [x] sync, status and the pending dedup all use it and no longer filter on their own
- [x] Pending dedup behaviour (multiset match on date and amount) is unchanged
- [x] All tests pass unchanged

## Summary of Changes

- mm_classify_transactions in the MoneyMoney module splits exported transactions into {synced, unsynced, pending}; it is the only code that looks at .booked or categoryUuid
- sync posts the Unsynced group plus new Pending Transactions; the YNAB payload and dry-run rows are built per group instead of re-checking .booked
- new_pending_transactions takes the Pending group; dedup logic unchanged
- status counts .synced and .unsynced
- New characterization test for the [pending] marker in dry run; all other tests unchanged
