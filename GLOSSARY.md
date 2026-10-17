# Flusso

Flusso syncs transactions from MoneyMoney (the source of truth) into a YNAB budget.

## Transactions

**Booked Transaction**:
A transaction MoneyMoney has finalized with the bank. Its identity is stable from then on.
_Avoid_: Cleared transaction, settled transaction

**Pending Transaction**:
A transaction the bank has announced but not yet booked (MoneyMoney: "vorgemerkter Umsatz"). MoneyMoney replaces it with a new Booked Transaction once it is booked.
_Avoid_: Vorgemerkt (in code and output), unbooked transaction, pending as a synonym for unsynced

**Synced Transaction**:
A Booked Transaction that has been sent to YNAB and marked with the Sync Category.

**Unsynced Transaction**:
A Booked Transaction that has not been marked with the Sync Category yet.
_Avoid_: Pending, new, uncategorized

## Sync bookkeeping

**Sync Category**:
The MoneyMoney category that marks a transaction as synced.
_Avoid_: Label, tag, YNAB category

**Mark as synced**:
Assigning the Sync Category to a transaction in MoneyMoney.
_Avoid_: Categorize, label

## Accounts

**MoneyMoney Account**:
An account in MoneyMoney, identified by its account number (IBAN, card or depot number).
_Avoid_: Bank account, source account

**YNAB Account**:
The account in the YNAB budget that a MoneyMoney Account syncs into.
_Avoid_: Target account

**Account Mapping**:
The pairing of one MoneyMoney Account with one YNAB Account, with its own name, sync mode and optional start date.
_Avoid_: Account (on its own, when the mapping is meant), link

**Brokerage Account**:
A MoneyMoney Account holding securities, whose value changes with the market rather than through individual transactions.
_Avoid_: Depot, investment account

## Sync modes

**Transaction Sync**:
The sync mode that sends each Unsynced Transaction of a MoneyMoney Account to YNAB individually.
_Avoid_: Transactions mode, normal sync

**Balance Sync**:
The sync mode that brings a YNAB Account's balance in line with its MoneyMoney Account through a single Balance Adjustment. Used for Brokerage Accounts.
_Avoid_: Balance mode, depot sync

**Balance Adjustment**:
The one YNAB transaction a Balance Sync posts to cover the difference between the MoneyMoney and YNAB balances.
_Avoid_: Correction, reconciliation
