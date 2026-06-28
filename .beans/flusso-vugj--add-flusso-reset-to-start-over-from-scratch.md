---
# flusso-vugj
title: Add 'flusso reset' to start over from scratch
status: completed
type: feature
priority: normal
created_at: 2026-06-28T11:23:50Z
updated_at: 2026-06-28T11:25:17Z
---

Add a 'reset' subcommand that lets the user start flusso configuration over from scratch (e.g. after a YNAB fresh start), backing up the existing config and re-running the setup wizard so the start date and account mappings can be set again.

## Summary of Changes

Added a `flusso reset` subcommand (`cmd_reset`) that lets the user start configuration over from scratch (e.g. after a YNAB fresh start or when changing the start date / budget).

- Confirms before acting; backs up existing `~/.flusso/config.json` to `config.json.bak` (umask 077) then re-runs the full `setup` wizard, which overwrites the config.
- If no config exists, it skips the backup and starts a fresh setup.
- Aborting leaves everything untouched.
- Wired into the dispatcher and added to `--help` and README command docs/examples.
