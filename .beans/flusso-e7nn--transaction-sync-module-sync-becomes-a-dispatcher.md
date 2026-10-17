---
# flusso-e7nn
title: Transaction Sync module; sync becomes a dispatcher
status: completed
type: task
priority: normal
tags:
    - ready-for-agent
created_at: 2026-10-17T10:21:11Z
updated_at: 2026-10-17T10:24:50Z
parent: flusso-4ctd
blocked_by:
    - flusso-ygm7
    - flusso-urtt
---

## Parent

flusso-4ctd: Deepen Transaction Sync into its own module

## What to build

Transaction Sync for one Account Mapping becomes its own module, shaped like Balance Sync's. It takes the mapping's MoneyMoney Account, YNAB Account and start date plus the dry-run and include-pending flags, and handles everything for that mapping:

- uses the export-and-classify module
- dedups Pending Transactions when the user opts in
- renders the dry-run table
- builds the YNAB transactions from one MoneyMoney → YNAB definition (Unsynced: cleared with `import_id`; Pending: uncleared without `import_id`)
- creates them through the YNAB module
- marks the Unsynced Transactions as synced

It reports how many it synced (or would sync) to the caller, following Balance Sync's convention. The sync command is left with parsing flags, loading mappings, filtering by `--account`, dispatching on mode and printing the totals. Users see no change, and Pending Transactions stay opt-in.

## Acceptance criteria

- [x] Transaction Sync for one Account Mapping is its own module and reports its count the way Balance Sync does
- [x] YNAB transactions are built from MoneyMoney transactions in exactly one place
- [x] The sync command contains no per-transaction logic; it dispatches on balance / transactions / unknown mode and adds up the totals
- [x] Pending Transactions are synced only with `include_pending: true` or `--include-pending`
- [x] Output text, exit codes and dedup behaviour (ADR 0001) are unchanged; the full bats suite passes unmodified

## Summary of Changes

Extracted `sync_transactions` (new section "sync: transaction mode"), which has the same shape as `sync_balance`: it takes the MoneyMoney Account, YNAB Account, start date, dry-run and include-pending flags, prints the per-mapping output, sets `TRANSACTIONS_SYNCED`, and returns non-zero when the mapping failed. `cmd_sync` now only parses flags, filters by `--account`, dispatches on mode and adds up the totals. The live and dry-run totals share one counter. Suite 56/56 green.
