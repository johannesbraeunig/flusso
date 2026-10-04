---
# flusso-rhs7
title: Support savings and brokerage accounts (balance sync + add-account)
status: completed
type: feature
priority: normal
created_at: 2026-10-04T18:39:47Z
updated_at: 2026-10-04T18:47:48Z
---

Savings accounts (Tagesgeld) already work via transaction sync but require full re-setup to add. Brokerage accounts (Depot) have no transactions in MoneyMoney — sync their balance instead by posting the difference as an adjustment.

- [x] Per-account `mode`: transactions (default) | balance
- [x] Balance sync: compare MoneyMoney balance with YNAB balance, post adjustment
- [x] Setup auto-detects portfolio accounts and suggests balance mode
- [x] `flusso add` command to add accounts to existing config
- [x] status shows balance accounts
- [x] README/help updated

## Summary of Changes

- New per-account `mode` field: `transactions` (default) or `balance`.
- Balance mode compares MoneyMoney's account balance with the YNAB account balance and posts the difference as a single "Balance Adjustment" transaction (import_id `FLUSSO:BAL:<date>:<amount>`).
- Account mapping extracted into `map_accounts`, shared by `setup` and the new `flusso add` command; portfolio accounts are auto-detected and default to balance mode.
- `flusso add` appends mappings to the existing config and skips already-configured accounts.
- `status` shows in-sync / to-adjust state for balance accounts.
- README, help and config.example.json updated.

## Review Fixes

- Missing YNAB balance no longer treated as 0 (would have posted the full balance).
- Duplicate import_id responses reported as skipped instead of posted.
- Non-numeric YNAB account selection no longer crashes under `set -u`.
- Per-account start date validated during mapping.
- Warning when the entered account number is unknown to MoneyMoney.
