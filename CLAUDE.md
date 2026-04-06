# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Flusso — a macOS CLI tool that syncs MoneyMoney transactions to YNAB.

### Architecture

- **`flusso`** — single bash script CLI with subcommands: `setup`, `sync`, `status`
- Config at `~/.flusso/config.json`
- No external state files — a MoneyMoney category is the single source of truth for dedup

### Sync pipeline

`osascript` (AppleScript → MoneyMoney plist export) → `sed` (convert date elements) → `plutil` (plist → JSON) → `jq` (filter by booked + not in sync category) → `curl` (POST to YNAB API) → `osascript` (assign sync category to transactions)

### Dedup strategy

Each synced transaction gets assigned a configurable MoneyMoney category (e.g. "YNAB Synced"). On next sync, transactions with this category are skipped. YNAB also deduplicates via `import_id`.

### Key dependencies

- `curl`, `jq`, `osascript`, `plutil` (all macOS built-ins except jq)
- MoneyMoney AppleScript API: https://moneymoney.app/applescript/
- YNAB API: https://api.ynab.com/v1

### Security considerations

- Config contains YNAB API token — file must be `600`, directory `700`
- All user inputs validated before passing to `osascript` to prevent injection
- Temp files cleaned up via `trap EXIT`

## Task Tracking

**IMPORTANT**: Before you do anything else, run the `beans prime` command and heed its output.

Uses [beans](https://github.com/hmans/beans) for local task management. Config in `.beans.yml`, tasks stored in `.beans/`. Task IDs are prefixed with `flusso-`. Use beans instead of TodoWrite for all work tracking.
