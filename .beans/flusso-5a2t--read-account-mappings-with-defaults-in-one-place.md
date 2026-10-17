---
# flusso-5a2t
title: Read Account Mappings with defaults in one place
status: completed
type: task
priority: low
created_at: 2026-10-17T09:40:23Z
updated_at: 2026-10-17T09:49:23Z
---

cmd_sync and cmd_status each read five to six fields per Account Mapping via jq -r ".accounts[$i]..." and each resolve the defaults themselves (mode defaults to transactions, start_date falls back to the global start date).

Deepen into one function that yields the Account Mappings with defaults already applied, so both commands iterate over resolved mappings.

Codebase-design candidate 4 (see flusso-cp3l, Out of Scope).

- [x] One function returns Account Mappings with mode and start date resolved
- [x] sync and status use it; no per-field config reads left in either loop
- [x] All sync and status tests pass unchanged

## Summary of Changes

- account_mappings prints each configured Account Mapping with defaults resolved (mode transactions, empty or missing start date falls back to the global one), fields separated by \x1f so empty values don't collapse
- sync and status loop over it on fd 3 (so nothing in the loop body can swallow the list from stdin); no per-field config reads left
- New test: empty per-mapping start date falls back to the global start date; all other tests unchanged
