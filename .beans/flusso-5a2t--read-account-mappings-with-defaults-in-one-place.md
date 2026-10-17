---
# flusso-5a2t
title: Read Account Mappings with defaults in one place
status: todo
type: task
priority: low
created_at: 2026-10-17T09:40:23Z
updated_at: 2026-10-17T09:40:23Z
---

cmd_sync and cmd_status each read five to six fields per Account Mapping via jq -r ".accounts[$i]..." and each resolve the defaults themselves (mode defaults to transactions, start_date falls back to the global start date).

Deepen into one function that yields the Account Mappings with defaults already applied, so both commands iterate over resolved mappings.

Codebase-design candidate 4 (see flusso-cp3l, Out of Scope).

- [ ] One function returns Account Mappings with mode and start date resolved
- [ ] sync and status use it; no per-field config reads left in either loop
- [ ] All sync and status tests pass unchanged
