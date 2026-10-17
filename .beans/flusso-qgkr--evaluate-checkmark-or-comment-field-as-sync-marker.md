---
# flusso-qgkr
title: Evaluate checkmark or comment field as sync marker
status: todo
type: task
priority: low
created_at: 2026-10-17T09:11:12Z
updated_at: 2026-10-17T09:38:32Z
blocked_by:
    - flusso-qo8n
---

ADR 0001 records the Sync Category as sync state. The cost: users can't use MoneyMoney categories for anything else, and recategorizing a Synced Transaction triggers a re-sync that overwrites the user's category.

Check whether the transaction checkmark or comment field could serve as the sync marker instead.

- [ ] Check in the MoneyMoney AppleScript docs (https://moneymoney.app/applescript/) whether `set transaction` can write the checkmark and/or comment
- [ ] Check whether `export transactions` (plist) returns these fields, so the sync can filter by them
- [ ] Weigh the conflict with users who already use the checkmark or comments
- [ ] Recommendation: keep ADR 0001 or supersede it with a new ADR

## Notes

After flusso-qo8n, switching the sync marker touches two logic places, both in the MoneyMoney module: mm_classify_transactions (the check) and mm_mark_synced (the AppleScript). Outside the module, only the Sync Category plumbing would change: config loading, setup, three call sites passing the UUID, and the "marked as synced with ..." output line.
