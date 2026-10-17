---
# flusso-etv6
title: Optionally sync pending (vorgemerkte) transactions
status: completed
type: feature
priority: normal
created_at: 2026-10-17T09:01:37Z
updated_at: 2026-10-17T09:03:25Z
---

Allow syncing MoneyMoney pending (booked == false) transactions to YNAB as uncleared.

Approach:
- Pending tx posted WITHOUT import_id, cleared=uncleared. When the booked version is synced later (with import_id), YNAB auto-matches it to the user-entered tx (same amount, date ±10 days).
- Pending tx are NOT categorized in MoneyMoney (booking replaces the entry; category would be lost or wrongly carried over). Dedup instead against YNAB: skip pending whose (date, amount) already exists in the YNAB account.
- Opt-in via config key include_pending or sync flag --include-pending.

- [x] Config key + --include-pending flag
- [x] Fetch YNAB tx for dedup, post pending as uncleared
- [x] Dry-run output marks pending
- [x] README + help
- [x] Test with dry run

## Summary of Changes

- New `include_pending` config key and `sync --include-pending` flag (default off).
- `new_pending_transactions` fetches YNAB account transactions since start date and drops pending entries already present (date+amount multiset, only non-deleted tx without import_id).
- Pending tx posted as `uncleared` without `import_id`; only booked tx get the MoneyMoney sync category.
- Dry run marks pending rows; README, help, config example and CLAUDE.md updated.
