---
# flusso-pons
title: Characterization tests for status
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

The current behaviour of `flusso status` is pinned by tests at the CLI seam, so the following refactors can be verified without changing any test. Can run in parallel with the sync characterization tests.

## Acceptance criteria

- [ ] A Transaction Sync mapping shows the correct synced and unsynced counts and the start date
- [ ] A Balance Sync mapping shows "in sync" or the amount to adjust
- [ ] A Balance Sync mapping shows "unavailable" when MoneyMoney or YNAB can't be reached
- [ ] A failed MoneyMoney transaction export doesn't crash status
- [ ] Tests assert only on exit status, output and the fakes' call logs
