---
# flusso-8njj
title: Share the Balance Sync difference between sync and status
status: todo
type: task
priority: low
created_at: 2026-10-17T09:40:23Z
updated_at: 2026-10-17T09:40:23Z
---

sync_balance and cmd_status both look up the MoneyMoney balance of a Brokerage Account (jq over the account export), fetch the YNAB Account balance and compute the difference. Both copies must change together.

Deepen into one function (e.g. balance_diff <mm_account> <ynab_account_id> <mm_accounts>) that returns the MoneyMoney balance, YNAB balance and difference, or fails. sync posts the Balance Adjustment from it; status only displays it.

Codebase-design candidate 3 (see flusso-cp3l, Out of Scope).

- [ ] One function computes MoneyMoney balance, YNAB balance and difference
- [ ] sync_balance and status use it; no balance lookup left elsewhere
- [ ] Existing Balance Sync tests in sync.bats and status.bats pass unchanged
