---
# flusso-qo8n
title: Shared transaction classification
status: todo
type: task
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:15:10Z
parent: flusso-cp3l
blocked_by:
    - flusso-9via
---

## Parent

flusso-cp3l

## What to build

One classification splits a MoneyMoney Account's transactions into Synced, Unsynced and Pending Transactions (as defined in GLOSSARY.md), given the Sync Category. `sync` posts the Unsynced group (plus new Pending Transactions when enabled), `status` counts Synced and Unsynced, and the pending dedup against YNAB consumes the Pending group. The rules for "is this synced?" then live in one place, which unblocks flusso-qgkr.

## Acceptance criteria

- [ ] A single classification is the only place that decides Synced vs Unsynced vs Pending
- [ ] sync, status and the pending dedup all use it and no longer filter on their own
- [ ] Pending dedup behaviour (multiset match on date and amount) is unchanged
- [ ] All tests pass unchanged
