---
# flusso-ygm7
title: Create transactions in YNAB through one module
status: todo
type: task
tags:
    - ready-for-agent
created_at: 2026-10-17T10:21:10Z
updated_at: 2026-10-17T10:21:10Z
parent: flusso-4ctd
blocked_by:
    - flusso-nyi0
---

## Parent

flusso-4ctd: Deepen Transaction Sync into its own module

## What to build

One module in the YNAB API section that creates transactions in YNAB. It takes a create-transactions payload (one transaction or many), POSTs it, and reports the created and duplicate counts. If the request fails, it fails with the response text so the caller can show it. Balance Sync and the current inline Transaction Sync both use it, so neither parses `transaction_ids` / `duplicate_import_ids` itself any more. Users see no change.

## Acceptance criteria

- [ ] One module POSTs a create-transactions payload and reports created and duplicate counts, or fails with the response text
- [ ] Balance Sync uses it to tell a posted Balance Adjustment from one already imported today
- [ ] Transaction Sync uses it for the "N created, M duplicates skipped." line and the run total
- [ ] No other code parses the YNAB create-transactions response
- [ ] Output text and exit codes are unchanged; the full bats suite passes unmodified
