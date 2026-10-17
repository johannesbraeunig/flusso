---
# flusso-9via
title: MoneyMoney module
status: completed
type: task
priority: normal
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:35:36Z
parent: flusso-cp3l
blocked_by:
    - flusso-odqj
    - flusso-pons
---

## Parent

flusso-cp3l

## What to build

Every interaction with MoneyMoney goes through one module with a small interface: export accounts, export categories, export transactions for a MoneyMoney Account since a start date (validated, converted, normalized to an array), and mark transactions as synced. A single internal plist-to-JSON conversion replaces the three current variants. `sync`, `status` and `setup` use the module and contain no AppleScript, plist or normalization code anymore. The only intended behaviour change: `status` now rejects an invalid account number the same way `sync` does.

## Acceptance criteria

- [x] All AppleScript calls to MoneyMoney live in the module
- [x] One plist-to-JSON conversion (data blobs replaced, date elements converted) is used for every export
- [x] The transaction export validates account number and start date and always returns an array
- [x] Marking as synced is one module operation that reports how many succeeded
- [x] New test: status rejects an invalid account number like sync does
- [x] All sync and status characterization tests pass unchanged
- [x] Output, flags, config schema and YNAB payloads are unchanged (ADR 0001 still holds)

## Summary of Changes

- MoneyMoney module in flusso: mm_plist_to_json (one conversion for all exports), mm_export_accounts, mm_export_categories, mm_export_transactions (validates, converts, normalizes; named exit codes MM_EXPORT_FAILED / MM_PARSE_FAILED / MM_INVALID_INPUT; errors on stderr only, never mixed into JSON), mm_mark_synced (ids on stdin)
- setup, sync and status contain no AppleScript, plist or normalization code anymore
- status now validates account number and start date like sync (dies with the same message) — the start date part is a second, consistent behaviour change
- setup now dies with "Could not fetch categories from MoneyMoney." if the category export can't be parsed (it used to exit silently)
- check_deps lists perl; CLAUDE.md pipeline updated
- New tests: invalid account (sync, status), invalid start date (status), unparsable export (sync); all characterization tests unchanged
