---
# flusso-0c4g
title: Tests for setup, reset and add
status: completed
type: task
priority: normal
created_at: 2026-10-17T09:40:23Z
updated_at: 2026-10-17T09:46:05Z
---

Cover the interactive commands at the CLI seam (bats, fake osascript/curl, answers fed on stdin), so changes to the shared account mapping and MoneyMoney module are safe.

- [x] setup writes the config (token, budget, start date, Account Mapping, Sync Category) with restricted permissions
- [x] setup rejects an invalid token and writes no config
- [x] setup pre-selects Balance Sync for a Brokerage Account
- [x] setup warns about an unknown MoneyMoney account number
- [x] setup offers only non-group categories
- [x] reset backs up the config after confirmation and runs setup
- [x] reset aborts without changes when not confirmed
- [x] reset without config starts a fresh setup
- [x] add appends new Account Mappings and keeps existing ones
- [x] add skips already configured MoneyMoney Accounts
- [x] add stops when the configured budget no longer exists

## Summary of Changes

- test/setup.bats, test/reset.bats, test/add.bats cover the interactive commands at the CLI seam, with answers fed on stdin
- Shared helpers for fixtures (setup_fixtures, ynab_has_budget, mm_category) and answer sequences (setup_answers, transaction_mapping_answers, balance_mapping_answers), so a new prompt changes one place
- Each test verified to fail under a targeted mutation
- Found a real bug: umask 077 only protects newly created files, so an existing readable config or backup stayed readable. Fixed with write_private (separate commit).
