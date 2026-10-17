---
# flusso-yejj
title: Domain glossary and terminology cleanup
status: completed
type: task
priority: normal
created_at: 2026-10-17T09:08:49Z
updated_at: 2026-10-17T09:10:13Z
---

Build GLOSSARY.md via domain-modeling session and align code/README wording with it.

- [x] Resolve 'pending' (= vorgemerkt) vs unsynced
- [x] Resolve 'categorize' → Sync Category / mark as synced
- [x] Rename status count to 'unsynced', sync output to 'marked as synced'
- [x] Resolve account terminology (MoneyMoney account / YNAB account / mapping)
- [x] ADR 0001: Sync Category as sync state

## Summary of Changes

- Added GLOSSARY.md (transactions, sync bookkeeping, accounts, sync modes)
- Added docs/adr/0001-sync-category-as-sync-state.md
- flusso status: 'pending' count renamed to 'unsynced'; sync output says 'marked as synced'
- README wording aligned with the glossary
