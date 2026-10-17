# Sync Category as sync state

Flusso records which transactions are synced by assigning a MoneyMoney category (the Sync Category) to them. It keeps no state file of its own, so MoneyMoney stays the single source of truth: the state survives reinstalls and machine changes, and the user can see it in MoneyMoney. The cost is that Flusso users can't use MoneyMoney categories for anything else. This is acceptable because Flusso users budget in YNAB, not in MoneyMoney.

## Considered Options

- **State file in `~/.flusso/`**: rejected. It drifts from MoneyMoney, gets lost on a new machine, and would be a second source of truth.
- **Checkmark or comment field on the transaction**: not evaluated. It's unverified whether MoneyMoney's AppleScript API can write these, and users may already use them.

## Consequences

- If a user recategorizes a Synced Transaction in MoneyMoney, it becomes an Unsynced Transaction again. The next sync re-sends it, YNAB discards it as a duplicate via `import_id`, and Flusso marks it as synced again. That overwrites the user's category.
- Pending Transactions can't carry the Sync Category (MoneyMoney replaces them when they're booked), so they're deduplicated against YNAB instead.
