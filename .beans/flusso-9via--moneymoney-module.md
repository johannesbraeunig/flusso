---
# flusso-9via
title: MoneyMoney module
status: todo
type: task
tags:
    - ready-for-agent
created_at: 2026-10-17T09:15:10Z
updated_at: 2026-10-17T09:15:10Z
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

- [ ] All AppleScript calls to MoneyMoney live in the module
- [ ] One plist-to-JSON conversion (data blobs replaced, date elements converted) is used for every export
- [ ] The transaction export validates account number and start date and always returns an array
- [ ] Marking as synced is one module operation that reports how many succeeded
- [ ] New test: status rejects an invalid account number like sync does
- [ ] All sync and status characterization tests pass unchanged
- [ ] Output, flags, config schema and YNAB payloads are unchanged (ADR 0001 still holds)
