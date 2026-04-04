# Flusso

CLI tool that syncs [MoneyMoney](https://moneymoney.app) transactions to [YNAB](https://ynab.com) — one command, fully automated.

```
flusso sync
```

Flusso talks to MoneyMoney via AppleScript, fetches your transactions, filters out duplicates and pending entries, and sends everything to YNAB via their API. Synced transactions are categorized directly in MoneyMoney — no external state files needed.

## Prerequisites

- macOS (required for MoneyMoney + AppleScript)
- [MoneyMoney](https://moneymoney.app) installed and running
- [YNAB](https://ynab.com) account with a [Personal Access Token](https://app.ynab.com/settings/developer)
- `jq` (`brew install jq`)

## Installation

### Homebrew (recommended)

```bash
brew tap johannesbraeunig/flusso
brew install flusso
```

### Manual

```bash
git clone https://github.com/johannesbraeunig/flusso.git
cd flusso
sudo make install
```

This copies the `flusso` script to `/usr/local/bin`. To uninstall: `sudo make uninstall`.

## Quick Start

```bash
# 1. Configure YNAB token, budget, and account mappings
flusso setup

# 2. Sync transactions
flusso sync
```

On first run, macOS will ask you to grant automation access to your terminal for MoneyMoney.

## Commands

### `flusso setup`

Interactive wizard that:
1. Creates `~/.flusso/` directory (with restricted permissions)
2. Asks for your YNAB API token and validates it
3. Lets you pick a budget from your YNAB budgets
4. Maps MoneyMoney accounts to YNAB accounts
5. Sets a global start date (only transactions from this date onward are synced)
6. Selects a MoneyMoney category to mark synced transactions
7. Writes `~/.flusso/config.json`

### `flusso sync`

Syncs all configured accounts:
1. Fetches transactions from MoneyMoney via AppleScript
2. Filters: only booked transactions not yet in the sync category
3. Sends to YNAB API (payee name + memo/purpose)
4. Categorizes synced transactions in MoneyMoney

The category in MoneyMoney is the single source of truth — no state files to maintain. Re-running `flusso sync` only picks up uncategorized transactions.

**Options:**

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview what would be synced without sending |
| `--account <name>` | Sync only the named account |

```bash
flusso sync --dry-run                    # Preview
flusso sync --account "Checking"         # Sync one account
```

### `flusso status`

Shows sync state for all configured accounts by querying MoneyMoney directly:

```
$ flusso status

Flusso Status

  Checking Account          7 synced, 2 pending  since 2026-04-01
```

## Configuration

Config is stored at `~/.flusso/config.json`:

```json
{
  "api_token": "YOUR_YNAB_API_TOKEN",
  "budget_id": "YOUR_YNAB_BUDGET_ID",
  "start_date": "2026-04-01",
  "sync_category": {
    "uuid": "YOUR_MONEYMONEY_CATEGORY_UUID",
    "name": "YNAB Synced"
  },
  "accounts": [
    {
      "name": "Checking Account",
      "moneymoney_account": "DE00000000000000000000",
      "ynab_account_id": "YNAB_ACCOUNT_ID_1"
    },
    {
      "name": "Credit Card",
      "moneymoney_account": "1234********5678",
      "ynab_account_id": "YNAB_ACCOUNT_ID_2",
      "start_date": "2026-03-01"
    }
  ]
}
```

| Field | Description |
|-------|-------------|
| `api_token` | YNAB Personal Access Token |
| `budget_id` | YNAB budget ID (selected during setup) |
| `start_date` | Global cutoff — only sync transactions from this date onward |
| `sync_category.uuid` | MoneyMoney category UUID assigned to synced transactions |
| `sync_category.name` | Display name of the sync category |
| `accounts[].name` | Display name for the account |
| `accounts[].moneymoney_account` | Account number as shown in MoneyMoney (IBAN or card number) |
| `accounts[].ynab_account_id` | Corresponding YNAB account ID (selected during setup) |
| `accounts[].start_date` | Optional per-account override for the global start date |

## How It Works

```
flusso sync
    |
    |-- For each configured account:
    |
    |-- osascript: ask MoneyMoney to export transactions as plist
    |   +-- MoneyMoney returns XML plist data directly (no temp file)
    |
    |-- plutil: convert plist XML to JSON
    |
    |-- jq: filter (booked, not in sync category = not yet synced)
    |
    |-- curl: POST to YNAB API (/v1/budgets/{id}/transactions)
    |   +-- Fields: account_id, date, amount (milliunits), payee_name, memo, import_id
    |
    +-- osascript: assign sync category to each synced transaction in MoneyMoney
```

MoneyMoney is the single source of truth. The sync category on each transaction acts as both a visual indicator and dedup mechanism. YNAB also deduplicates on its end via `import_id`.

## License

MIT
