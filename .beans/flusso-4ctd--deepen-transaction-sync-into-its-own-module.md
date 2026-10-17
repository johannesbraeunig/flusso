---
# flusso-4ctd
title: Deepen Transaction Sync into its own module
status: todo
type: feature
tags:
    - ready-for-agent
created_at: 2026-10-17T10:19:05Z
updated_at: 2026-10-17T10:19:05Z
---

## Problem Statement

As the maintainer of Flusso, I find Transaction Sync hard to change safely. Balance Sync has its own module with a small interface. Transaction Sync instead lives inline in the sync command's per-mapping loop, as roughly a hundred lines that do everything:

- export from MoneyMoney and turn exit codes into messages
- classify Synced, Unsynced and Pending Transactions
- dedup Pending Transactions against YNAB
- render the dry-run table
- build the YNAB payload
- POST and parse the response
- mark the transactions as synced

The status command repeats the "export + error policy + classify" part with its own copy of the exit-code handling. Posting to YNAB and reading `transaction_ids` / `duplicate_import_ids` is repeated in Balance Sync and Transaction Sync.

So any change to the dedup rules (ADR 0001, plus the opt-in exception for Pending Transactions) means reading and editing the middle of a long command function, and keeping two copies of the MoneyMoney error handling consistent.

## Solution

Give Transaction Sync the same shape as Balance Sync: one module that syncs one Account Mapping and reports its outcome, so the sync command becomes a dispatcher on sync mode. The pieces Transaction Sync and status share (exporting and classifying a mapping's transactions) and the pieces it shares with Balance Sync (creating transactions in YNAB and reading the counts back) each become one deeper module.

Users see no change. Every command prints the same output and has the same exit status, and dedup works exactly as before.

## User Stories

1. As a Flusso user, I want `flusso sync` to post my Unsynced Transactions to YNAB exactly as before, so that the refactor doesn't change my budget.
2. As a Flusso user, I want Synced Transactions to stay skipped, so that nothing is posted twice.
3. As a Flusso user, I want each posted Unsynced Transaction to be marked as synced with the Sync Category afterwards, so that the next sync skips it.
4. As a Flusso user, I want the "N created, M duplicates skipped." line to stay, so that I can see what YNAB accepted.
5. As a Flusso user, I want the "N transaction(s) marked as synced with "<Sync Category>"." line to stay, so that I know MoneyMoney was updated.
6. As a Flusso user, I want "No new transactions." when an Account Mapping has nothing to sync, so that a quiet sync is obvious.
7. As a Flusso user, I want `--dry-run` to keep listing Unsynced Transactions in the same table without posting or marking, so that I can preview safely.
8. As a Flusso user, I want `--dry-run --include-pending` to keep tagging Pending Transactions with "[pending]" in the table, so that I can tell them apart.
9. As a Flusso user, I want Pending Transactions skipped unless I opt in with `include_pending: true` or `--include-pending`, so that syncing them stays opt-in.
10. As a Flusso user who opts in, I want Pending Transactions posted as uncleared without `import_id` and never marked as synced, so that YNAB can later match the booked version to them.
11. As a Flusso user who opts in, I want Pending Transactions already in YNAB (same date and amount, multiset match) skipped, so that repeated syncs don't duplicate them.
12. As a Flusso user who opts in, I want a failed fetch of YNAB transactions to skip only the Pending Transactions, with the existing error message, so that my Booked Transactions still sync.
13. As a Flusso user, I want a failed MoneyMoney export to print the existing hint about MoneyMoney running and automation access, then continue with the next Account Mapping, so that one broken account doesn't stop the rest.
14. As a Flusso user, I want an unparseable MoneyMoney export to print the existing parse error and continue with the next Account Mapping, so that one broken account doesn't stop the rest.
15. As a Flusso user, I want an invalid account number or start date to stop the sync before MoneyMoney is called, so that bad config never reaches AppleScript.
16. As a Flusso user, I want a failed YNAB POST to print the existing error with the response and continue with the next Account Mapping, without marking anything as synced, so that no transaction is marked as synced unless YNAB has it.
17. As a Flusso user, I want the final "Sync complete. N transaction(s) synced." and "Dry run complete. N transaction(s) would be synced." totals to stay correct, including the Balance Adjustment note, so that the summary matches what happened.
18. As a Flusso user, I want `--account <name>` to keep syncing only the named Account Mapping, so that I can sync one account.
19. As a Flusso user, I want Balance Sync to keep posting one Balance Adjustment and to report one already imported today as skipped, so that Brokerage Accounts behave as before.
20. As a Flusso user, I want `flusso status` to keep showing "N synced, M unsynced since <date>" for each Transaction Sync mapping, so that I can see the sync state.
21. As a Flusso user, I want `flusso status` to keep showing zero counts for a mapping whose MoneyMoney export fails or can't be parsed, and to keep reporting the other mappings, so that status never aborts on one account.
22. As a Flusso user, I want `flusso status` to keep stopping on an invalid account number or start date, so that it validates exactly as sync does.
23. As the maintainer, I want the rules for building a YNAB transaction from a MoneyMoney transaction (date, milliunit amount, payee fallback, memo, `cleared`, `import_id`) in one place, so that a change to them is a one-place edit.
24. As the maintainer, I want MoneyMoney export failures turned into user-facing outcomes in one place, so that sync and status can't drift apart.
25. As the maintainer, I want one module for creating transactions in YNAB that returns the created and duplicate counts, so that Balance Sync and Transaction Sync don't each parse the response.
26. As the maintainer, I want the sync command to read as a dispatcher over Account Mappings and sync modes, so that I can see the control flow at a glance.
27. As the maintainer, I want the existing bats suite to pass unchanged, so that the refactor provably preserves behaviour.

## Implementation Decisions

- **Transaction Sync module** (new). Syncs one Account Mapping in Transaction Sync. Inputs: the mapping's MoneyMoney Account, YNAB Account id and start date, plus the dry-run and include-pending flags. It reads the loaded config (Sync Category, budget) the same way the existing modules do. It prints the per-mapping output it prints today and reports how many transactions it synced (or would sync, in a dry run). The caller adds that to the run's totals. Follow `sync_balance`'s convention: report through a variable the caller resets before each call, and return non-zero only when the mapping failed. Invalid input (invalid account number or start date) still stops the whole run, as today.
- **Unsynced work for a mapping** (new, internal to Transaction Sync but shared with status). Exports a mapping's transactions and classifies them with the existing classification. It owns the policy that turns the MoneyMoney export exit codes into outcomes: invalid input stops the run, and a failed or unparseable export is reported to the caller as a failure with its reason. Sync turns that failure into the existing messages. Status turns it into zero counts, as it does today. The MoneyMoney `mm_*` functions stay the only place that touches AppleScript, per the project architecture.
- **MoneyMoney → YNAB transaction mapping** (internal). One jq definition builds YNAB transactions from Unsynced Transactions (cleared, `import_id` "tx_<id>") and Pending Transactions (uncleared, no `import_id`). It stays an internal piece of the Transaction Sync module, not a separate interface.
- **YNAB transaction creation** (new, in the YNAB API section). Takes a create-transactions payload (one or many transactions), POSTs it, and reports "CREATED DUPLICATES", or fails with the response text so the caller can show it. Balance Sync uses it to detect an adjustment already imported today. Transaction Sync uses it for its counts.
- **Sync command** becomes a dispatcher: parse flags, load the mappings, filter by `--account`, dispatch on mode (balance / transactions / unknown), add up the totals, print the summary. The once-per-run cache of the MoneyMoney account export for Balance Sync stays where it is.
- **Pending dedup** (`new_pending_transactions`) keeps its interface and stays where it is. Transaction Sync calls it.
- No change to the config schema, CLI flags, output text, exit codes, or the dedup strategy in ADR 0001.

## Testing Decisions

- A good test drives the `flusso` CLI the way a user does and asserts only on what's visible from outside: stdout/stderr, exit status, the requests sent to YNAB (fake `curl` log), and the MoneyMoney commands issued (fake `osascript` log). Tests never call internal functions or source the script.
- One seam only: the existing CLI seam with the fake `osascript` and `curl` on PATH. No new seam is introduced. The internal jq filters aren't tested directly.
- `test/sync.bats` and `test/status.bats` are the regression net and must pass unmodified.
- Add CLI tests only for behaviour that isn't covered yet and that the refactor touches, notably:
  - a failed YNAB POST in Transaction Sync prints the error, marks nothing as synced, and continues with the next Account Mapping
  - a Balance Adjustment already imported today is reported as skipped
  - the run totals across several Account Mappings, mixing Transaction Sync and Balance Sync
- Prior art: the fixture builders in `test/test_helper.bash` (`mm_tx`, `mm_has_transactions`, `ynab_route`, `ynab_accepts_transactions`, `posted_transactions`, `marked_as_synced`) and the existing tests for failure-and-continue in sync.bats.

## Out of Scope

- Moving the Account Mapping schema into one Config module (the inverse default rules in the interactive mapping, the merge in `add`, setup's config write). This is a separate candidate.
- Missing input checks in the interactive mapping: the account number isn't checked at entry, and the date check is duplicated. This belongs to the Config candidate.
- A shared "choose from a numbered list" prompt for budgets, YNAB Accounts and categories.
- Any change to the dedup strategy, the sync marker (see flusso-qgkr), or Pending Transaction handling.
- Splitting the single-file script into several files.

## Further Notes

- This came out of a codebase-design review that ranked deepening candidates. It continues the recent `balance_diff` and `account_mappings` refactors.
- Keep the vocabulary in GLOSSARY.md (Account Mapping, Transaction Sync, Unsynced/Synced/Pending Transaction, Sync Category, Mark as synced, Balance Adjustment) in function names and comments.
