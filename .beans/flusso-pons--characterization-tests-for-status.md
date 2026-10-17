---
# flusso-pons
title: Characterization tests for status
status: completed
type: task
priority: normal
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:31:14Z
parent: flusso-cp3l
blocked_by:
    - flusso-8yx9
---

## Parent

flusso-cp3l

## What to build

The current behaviour of `flusso status` is pinned by tests at the CLI seam, so the following refactors can be verified without changing any test. Can run in parallel with the sync characterization tests.

## Acceptance criteria

- [x] A Transaction Sync mapping shows the correct synced and unsynced counts and the start date
- [x] A Balance Sync mapping shows "in sync" or the amount to adjust
- [x] A Balance Sync mapping shows "unavailable" when MoneyMoney or YNAB can't be reached
- [x] A failed MoneyMoney transaction export doesn't crash status
- [x] Tests assert only on exit status, output and the fakes' call logs

## Summary of Changes

9 bats tests in test/status.bats pin the current behaviour of `flusso status`: synced/unsynced counts (Pending Transactions excluded), per-mapping start date, Balance Sync in sync / amount to adjust / unavailable (MoneyMoney unreachable, YNAB unreachable, account unknown), and failed or unparsable transaction exports not stopping other mappings. Each was verified to fail under a targeted mutation.

Found and fixed along the way (separate commits): [[ ]] assertions were no-ops under bash 3.2, and flusso's temp file cleanup could delete files of concurrent runs.
