---
# flusso-cp3l
title: Deepen MoneyMoney access and transaction classification
status: todo
type: feature
tags:
    - ready-for-agent
created_at: 2026-10-17T09:14:02Z
updated_at: 2026-10-17T09:14:02Z
---

## Problem Statement

As the maintainer of Flusso, I can't change how Flusso reads from or writes to MoneyMoney without touching several commands. Exporting transactions from MoneyMoney is copied into both `sync` and `status`. Converting plist to JSON exists in three slightly different variants. Normalizing the transaction list is copied four times. The rules that decide whether a transaction is a Synced, Unsynced or Pending Transaction are spread across `sync`, `status` and the pending dedup.

The copies have already drifted apart: `status` passes the account number and start date to MoneyMoney without the input validation `sync` applies. There are no tests at all, so every change has to be verified by hand against a real MoneyMoney and YNAB. The planned evaluation of another sync marker (checkmark or comment field instead of the Sync Category, see flusso-qgkr) would currently mean edits in three places across two commands.

## Solution

All MoneyMoney access sits behind one MoneyMoney module with a small interface: export accounts, export categories, export transactions for a MoneyMoney Account since a start date (already validated, converted and normalized), and mark transactions as synced. A single classification splits a MoneyMoney Account's transactions into Synced, Unsynced and Pending Transactions, and both `sync` and `status` use it, so they can't disagree.

Users see no change in behaviour or output. As the maintainer, I get an automated test suite that runs `flusso sync` and `flusso status` as real processes against fake MoneyMoney and YNAB, on any machine, without a MoneyMoney installation or a YNAB token.

## User Stories

1. As the Flusso maintainer, I want all MoneyMoney AppleScript calls behind one module, so that I change MoneyMoney behaviour in exactly one place.
2. As the Flusso maintainer, I want one way to turn a MoneyMoney plist export into JSON, so that fixes (icons as data blobs, date elements) apply to every export.
3. As the Flusso maintainer, I want transaction exports to come back as a normalized array, so that callers never handle MoneyMoney's single-object vs array shapes.
4. As the Flusso maintainer, I want the account number and start date validated inside the transaction export, so that no command can pass unvalidated input to AppleScript.
5. As the Flusso maintainer, I want marking a transaction as synced to be a single module operation, so that the sync marker can later move to another field (flusso-qgkr) without touching commands.
6. As the Flusso maintainer, I want one classification of a MoneyMoney Account's transactions into Synced, Unsynced and Pending Transactions, so that `sync` and `status` always agree.
7. As the Flusso maintainer, I want the classification to use the glossary's terms, so that code, output and docs speak the same language.
8. As a Flusso user, I want `flusso status` to count Unsynced Transactions exactly the way `flusso sync` would pick them up, so that status tells me what the next sync will do.
9. As a Flusso user, I want `flusso sync` to behave and print exactly as before, so that the refactor doesn't disrupt my workflow.
10. As a Flusso user, I want `flusso status` to print exactly as before, so that nothing I rely on changes.
11. As a Flusso user, I want Pending Transactions to be handled exactly as before when include_pending is on, so that YNAB matching keeps working.
12. As a Flusso user, I want a MoneyMoney export failure to keep producing the same error message and to skip only the affected Account Mapping, so that one broken account doesn't stop the whole sync.
13. As a Flusso user, I want an invalid account number in my config to produce the same clear error in both `sync` and `status`.
14. As the Flusso maintainer, I want to run the test suite with one command, so that I can verify a change in seconds.
15. As the Flusso maintainer, I want tests to run without MoneyMoney or network access, so that they can run in CI and on any Mac.
16. As the Flusso maintainer, I want fake `osascript` and `curl` commands that serve fixture data, so that tests control what MoneyMoney and YNAB return.
17. As the Flusso maintainer, I want the fakes to record how they were called, so that tests can assert which transactions were posted to YNAB and which were marked as synced.
18. As the Flusso maintainer, I want tests to use a temporary home directory with a test config, so that they never touch my real `~/.flusso`.
19. As the Flusso maintainer, I want a test proving that an Unsynced Transaction is posted to YNAB and then marked as synced.
20. As the Flusso maintainer, I want a test proving that a Synced Transaction is neither posted nor marked again.
21. As the Flusso maintainer, I want a test proving that Pending Transactions are skipped unless include_pending or `--include-pending` is set.
22. As the Flusso maintainer, I want a test proving that Pending Transactions are posted as uncleared without import_id and are never marked as synced.
23. As the Flusso maintainer, I want a test proving that a Pending Transaction already in YNAB (same date and amount) isn't posted again, including two identical Pending Transactions where only one exists in YNAB.
24. As the Flusso maintainer, I want a test proving that `--dry-run` posts nothing and marks nothing.
25. As the Flusso maintainer, I want a test proving that `--account` limits the sync to one Account Mapping.
26. As the Flusso maintainer, I want a test proving that `status` reports the correct synced and unsynced counts for a Transaction Sync mapping.
27. As the Flusso maintainer, I want a test proving that `status` and `sync` reject an invalid account number the same way.
28. As the Flusso maintainer, I want a test covering a MoneyMoney export that returns a single transaction object instead of an array.
29. As the Flusso maintainer, I want a test proving that a failed MoneyMoney export skips the Account Mapping with an error and continues with the next one.
30. As the Flusso maintainer, I want a test for a Balance Sync mapping (Balance Adjustment posted, or "up to date"), so that the existing behaviour is covered before neighbouring code changes.
31. As the Flusso maintainer, I want tests that describe behaviour visible from the command line, so that they survive future internal refactors.

## Implementation Decisions

- **MoneyMoney module.** Introduce one module that owns every interaction with MoneyMoney. Its interface:
  - export accounts: returns the non-group MoneyMoney Accounts as JSON
  - export categories: returns the non-group categories as JSON
  - export transactions (MoneyMoney Account, start date): validates both inputs, exports, converts, and returns a normalized JSON array
  - mark as synced (Sync Category, transaction ids): assigns the Sync Category and reports how many succeeded
- **One internal plist-to-JSON conversion** inside the module, which always replaces data blobs and converts date elements. It replaces the three current variants. This is an internal seam of the module, not part of its interface.
- **Classification.** One operation takes a normalized transaction array and the Sync Category, and returns the transactions grouped into Synced, Unsynced and Pending Transactions, as defined in the glossary. `sync` posts Unsynced (plus new Pending, if enabled). `status` counts Synced and Unsynced.
- **Pending dedup against YNAB** keeps its current behaviour (multiset match on date and amount among YNAB transactions without import_id). It now consumes the Pending group from the classification instead of filtering by itself.
- **Commands keep their responsibilities.** `sync` and `status` keep flag parsing, output formatting, the YNAB payload and the error messages. They lose all direct AppleScript, plist and normalization code.
- **No user-visible change.** CLI flags, output text, the config schema and YNAB payloads (including import_id formats) stay identical.
- **ADR 0001 is respected.** The Sync Category remains the sync state. The module only localizes it, so that a later decision on flusso-qgkr changes only the module.
- **Balance Sync stays as it is**, apart from using the module's account export.

## Testing Decisions

- **One seam: the CLI process.** Tests run the real `flusso` executable as a subprocess. No in-process or function-level tests, and no source guard in the script.
- **Adapters at that seam.** Fake `osascript` and `curl` executables come first on PATH. They serve fixture plist and JSON responses chosen per test, and append each invocation (arguments, and for `curl` the posted body) to a log the test can read. Together with the real binaries, these are the second adapter, which makes this a real seam rather than a hypothetical one.
- **Isolation.** Each test sets HOME to a fresh temporary directory containing a test config, so the real `~/.flusso` is never read or written.
- **What a good test is.** It asserts only on observable behaviour: exit status, stdout and stderr text, the transactions posted to the fake YNAB, and the transactions marked as synced in the fake MoneyMoney. It never asserts on internal function names or intermediate JSON. A test that has to change during an internal refactor is testing past the interface.
- **Write characterization tests first.** Write the CLI tests against the current script before refactoring, so the refactor is verified by unchanged tests.
- **Scope of tests.** `sync` (transaction mode, pending, dry run, account filter, error paths, balance mode) and `status` (both modes). `setup`, `reset` and `add` are interactive and stay out of scope.
- **Framework.** bats-core (available via Homebrew). Invoked through a make target, so one command runs everything.
- **Prior art.** None. The repo has no tests yet. This spec introduces the test layout and the fixture conventions.

## Out of Scope

- Changing the sync marker (checkmark or comment field instead of the Sync Category). That's flusso-qgkr; this spec only makes it cheap.
- Deduplicating the Balance Sync diff between `sync` and `status` (codebase-design candidate 3).
- Consolidating how Account Mappings are read from the config (candidate 4).
- Tests for the interactive commands `setup`, `reset` and `add`.
- Any change to CLI output, flags, config schema or YNAB payloads.
- CI setup (GitHub Actions). The suite only needs to be CI-ready.

## Further Notes

- Terms follow GLOSSARY.md: Synced/Unsynced/Pending Transaction, Sync Category, mark as synced, MoneyMoney Account, Account Mapping, Transaction Sync, Balance Sync, Balance Adjustment.
- Fixture plists should be taken from real MoneyMoney exports with personal data replaced. The single-object vs array shape and the date elements must both be represented.
- This came out of a codebase-design review (deep modules). Candidates 1 and 2 were picked because they offer the most leverage and locality.
