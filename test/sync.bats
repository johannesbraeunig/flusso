#!/usr/bin/env bats

load test_helper

@test "sync posts an Unsynced Transaction to YNAB and marks it as synced" {
  write_config
  mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries" | mm_has_transactions
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"1 created, 0 duplicates skipped."* ]] || false
  [ "$(posted_transactions)" = "$(jq -n --arg acct "$YNAB_CHECKING" '[{
    account_id: $acct,
    date: "2026-04-03",
    amount: -42500,
    payee_name: "Supermarket GmbH",
    memo: "Groceries",
    cleared: "cleared",
    import_id: "tx_101"
  }]')" ]
  [ "$(marked_as_synced)" = "101" ]
}

@test "sync skips Synced Transactions" {
  write_config
  {
    mm_tx 101 2026-04-03 -42.5 true "$SYNC_CATEGORY_UUID" "Supermarket GmbH" "Groceries"
    mm_tx 102 2026-04-04 -9.99 true "" "Streaming Service" ""
  } | mm_has_transactions
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"1 new transaction(s) found."* ]] || false
  [ "$(posted_transactions | jq -r '.[].import_id')" = "tx_102" ]
  [ "$(marked_as_synced)" = "102" ]
}

@test "sync reports no new transactions when everything is synced" {
  write_config
  mm_tx 101 2026-04-03 -42.5 true "$SYNC_CATEGORY_UUID" "Supermarket GmbH" "Groceries" | mm_has_transactions

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"No new transactions."* ]] || false
  [ "$(posted_transactions)" = "[]" ]
  [ -z "$(marked_as_synced)" ]
}

@test "sync --dry-run lists Unsynced Transactions without posting or marking" {
  write_config
  {
    mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries"
    mm_tx 102 2026-04-04 3500 true "" "Employer Inc" "Salary April"
  } | mm_has_transactions

  run "$FLUSSO" sync --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"2026-04-03"*"-42.50"*"Supermarket GmbH"*"Groceries"* ]] || false
  [[ "$output" == *"2026-04-04"*"3500.00"*"Employer Inc"*"Salary April"* ]] || false
  [[ "$output" == *"Dry run complete. 2 transaction(s) would be synced."* ]] || false
  [ "$(posted_transactions)" = "[]" ]
  [ -z "$(marked_as_synced)" ]
}

@test "sync --account syncs only the named Account Mapping" {
  write_config '[
    {"name": "Checking", "moneymoney_account": "DE001", "ynab_account_id": "ynab-checking"},
    {"name": "Credit Card", "moneymoney_account": "1234****5678", "ynab_account_id": "ynab-card"}
  ]'
  mm_tx 201 2026-04-03 -9.99 true "" "Streaming Service" "" | mm_has_transactions "1234****5678"
  ynab_accepts_transactions 1

  run "$FLUSSO" sync --account "Credit Card"

  [ "$status" -eq 0 ]
  [ "$(exported_accounts)" = "1234****5678" ]
  [ "$(posted_transactions | jq -c '[.[] | {account_id, import_id}]')" = '[{"account_id":"ynab-card","import_id":"tx_201"}]' ]
  [ "$(marked_as_synced)" = "201" ]
}

@test "sync handles an export with a single transaction instead of a list" {
  write_config
  mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries" | mm_has_single_transaction
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [ "$(posted_transactions | jq -r '.[].import_id')" = "tx_101" ]
  [ "$(marked_as_synced)" = "101" ]
}

@test "sync reports a failed MoneyMoney export and continues with the next Account Mapping" {
  write_config '[
    {"name": "Checking", "moneymoney_account": "DE001", "ynab_account_id": "ynab-checking"},
    {"name": "Savings", "moneymoney_account": "DE002", "ynab_account_id": "ynab-savings"}
  ]'
  # No fixture for DE001, so its export fails
  mm_tx 301 2026-04-03 100 true "" "Transfer" "" | mm_has_transactions DE002
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"Error: Could not export from MoneyMoney."*"MoneyMoney fake has no export-transactions response"* ]] || false
  [ "$(posted_transactions | jq -c '[.[] | {account_id, import_id}]')" = '[{"account_id":"ynab-savings","import_id":"tx_301"}]' ]
  [ "$(marked_as_synced)" = "301" ]
}

@test "sync skips Pending Transactions by default" {
  write_config
  mm_tx 401 2026-04-05 -9.99 false "" "Cafe" "" | mm_has_transactions

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"No new transactions."* ]] || false
  # Not even the YNAB lookup for the pending dedup happens
  [ "$(ynab_requests)" = "[]" ]
}

@test "sync --include-pending posts Pending Transactions as uncleared without import_id and doesn't mark them" {
  write_config
  {
    mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries"
    mm_tx 401 2026-04-05 -9.99 false "" "Cafe" "Card payment"
  } | mm_has_transactions
  ynab_has_transactions "$YNAB_CHECKING" '[]'
  ynab_accepts_transactions 2

  run "$FLUSSO" sync --include-pending

  [ "$status" -eq 0 ]
  [[ "$output" == *"2 new transaction(s) found (1 pending)."* ]] || false
  [ "$(posted_transactions | jq -c '.[] | select(.payee_name == "Cafe")')" = "$(jq -cn --arg acct "$YNAB_CHECKING" '{
    account_id: $acct, date: "2026-04-05", amount: -9990, payee_name: "Cafe", memo: "Card payment", cleared: "uncleared"
  }')" ]
  [ "$(marked_as_synced)" = "101" ]
  [ "$(ynab_requests | jq -r '.[] | select(.method == "GET") | .path')" = \
    "/budgets/$BUDGET_ID/accounts/$YNAB_CHECKING/transactions?since_date=2026-04-01" ]
}

@test "sync honours include_pending in the config" {
  write_config "" '{"include_pending": true}'
  mm_tx 401 2026-04-05 -9.99 false "" "Cafe" "" | mm_has_transactions
  ynab_has_transactions "$YNAB_CHECKING" '[]'
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [ "$(posted_transactions | jq -r '.[].cleared')" = "uncleared" ]
}

@test "sync --include-pending skips Pending Transactions already in YNAB, counting duplicates" {
  write_config
  {
    mm_tx 401 2026-04-05 -9.99 false "" "Cafe" ""
    mm_tx 402 2026-04-05 -9.99 false "" "Cafe" ""
  } | mm_has_transactions
  # Only the transaction without import_id stands for an earlier Pending Transaction
  ynab_has_transactions "$YNAB_CHECKING" '[
    {"date": "2026-04-05", "amount": -9990, "import_id": null, "deleted": false},
    {"date": "2026-04-05", "amount": -9990, "import_id": "tx_99", "deleted": false},
    {"date": "2026-04-05", "amount": -9990, "import_id": null, "deleted": true}
  ]'
  ynab_accepts_transactions 1

  run "$FLUSSO" sync --include-pending

  [ "$status" -eq 0 ]
  [[ "$output" == *"1 new transaction(s) found (1 pending)."* ]] || false
  [ "$(posted_transactions | jq -c '[.[] | {cleared, has_import_id: has("import_id")}]')" = \
    '[{"cleared":"uncleared","has_import_id":false}]' ]
}

@test "sync --include-pending reports no new transactions when the Pending Transaction is already in YNAB" {
  write_config
  mm_tx 401 2026-04-05 -9.99 false "" "Cafe" "" | mm_has_transactions
  ynab_has_transactions "$YNAB_CHECKING" '[{"date": "2026-04-05", "amount": -9990, "import_id": null, "deleted": false}]'

  run "$FLUSSO" sync --include-pending

  [ "$status" -eq 0 ]
  [[ "$output" == *"No new transactions."* ]] || false
  [ "$(posted_transactions)" = "[]" ]
}

@test "Balance Sync posts a Balance Adjustment for the difference" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 123456789 10152.3 true | mm_has_accounts
  ynab_has_balance ynab-brokerage 10000000
  ynab_accepts_transactions 1
  local today
  today=$(date +%Y-%m-%d)

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"Adjustment of 152.30 posted."* ]] || false
  [ "$(posted_transactions)" = "$(jq -n --arg today "$today" '[{
    account_id: "ynab-brokerage",
    date: $today,
    amount: 152300,
    payee_name: "Balance Adjustment",
    memo: "MoneyMoney balance: 10152.30",
    cleared: "cleared",
    import_id: "FLUSSO:BAL:\($today):152300"
  }]')" ]
  [[ "$output" == *"1 balance adjustment(s) posted."* ]] || false
}

@test "Balance Sync posts nothing when the balances match" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 123456789 10000 true | mm_has_accounts
  ynab_has_balance ynab-brokerage 10000000

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"Balance up to date."* ]] || false
  [ "$(posted_transactions)" = "[]" ]
}

@test "sync leaves temp files of other flusso runs alone" {
  write_config
  mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries" | mm_has_transactions
  ynab_accepts_transactions 1
  # Stands in for the YNAB request body of a concurrent run
  local other="/tmp/flusso_bats$$.tmp"
  touch "$other"

  run "$FLUSSO" sync

  local survived=false
  [ -f "$other" ] && survived=true
  rm -f "$other"
  [ "$status" -eq 0 ]
  [ "$survived" = true ]
}

@test "sync removes its own temp files" {
  write_config
  mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries" | mm_has_transactions
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [ -z "$(ls -A "$TMPDIR")" ]
}

@test "sync rejects an invalid account number before calling MoneyMoney" {
  write_config '[{"name": "Checking", "moneymoney_account": "DE001\" & (do shell script \"id\") & \"", "ynab_account_id": "ynab-checking"}]'

  run "$FLUSSO" sync

  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Invalid account identifier: DE001"* ]] || false
  [ -z "$(transaction_exports)" ]
}

@test "sync reports a MoneyMoney export it can't parse and continues with the next Account Mapping" {
  write_config '[
    {"name": "Checking", "moneymoney_account": "DE001", "ynab_account_id": "ynab-checking"},
    {"name": "Savings", "moneymoney_account": "DE002", "ynab_account_id": "ynab-savings"}
  ]'
  mm_export_is_garbled DE001
  mm_tx 301 2026-04-03 100 true "" "Transfer" "" | mm_has_transactions DE002
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"Error: Could not parse plist data."* ]] || false
  [ "$(posted_transactions | jq -r '.[].import_id')" = "tx_301" ]
}

@test "sync --dry-run --include-pending marks Pending Transactions in the list" {
  write_config
  {
    mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" ""
    mm_tx 401 2026-04-05 -9.99 false "" "Cafe" ""
  } | mm_has_transactions
  ynab_has_transactions "$YNAB_CHECKING" '[]'

  run "$FLUSSO" sync --dry-run --include-pending

  [ "$status" -eq 0 ]
  [ "$(grep -F "Supermarket GmbH" <<< "$output" | grep -c "\[pending\]")" -eq 0 ]
  [ "$(grep -F "Cafe" <<< "$output" | grep -c "\[pending\]")" -eq 1 ]
  [ "$(posted_transactions)" = "[]" ]
}

@test "Balance Sync reports a Brokerage Account MoneyMoney doesn't know" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 999999999 10000 true | mm_has_accounts
  ynab_has_balance "$YNAB_BROKERAGE" 10000000

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"Error: Account not found in MoneyMoney."* ]] || false
  [ "$(posted_transactions)" = "[]" ]
}

@test "Balance Sync reports when the YNAB balance can't be fetched" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 123456789 10000 true | mm_has_accounts
  # No YNAB route, so the balance request fails

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"Error: Could not fetch YNAB account balance."* ]] || false
  [ "$(posted_transactions)" = "[]" ]
}

@test "sync stops on an Account Mapping without a YNAB Account" {
  write_config '[{"name": "Checking", "moneymoney_account": "DE001"}]'
  mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "" | mm_has_transactions
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Invalid Account Mapping in"* ]] || false
  [ -z "$(transaction_exports)" ]
  [ "$(posted_transactions)" = "[]" ]
}

@test "sync stops on an Account Mapping that isn't an object" {
  write_config '["DE001"]'

  run "$FLUSSO" sync

  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Invalid Account Mapping in"* ]] || false
}

@test "sync reports a failed YNAB request, marks nothing as synced and continues with the next Account Mapping" {
  write_config '[
    {"name": "Checking", "moneymoney_account": "DE001", "ynab_account_id": "ynab-checking"},
    {"name": "Savings", "moneymoney_account": "DE002", "ynab_account_id": "ynab-savings"}
  ]'
  mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries" | mm_has_transactions DE001
  mm_tx 301 2026-04-03 100 true "" "Transfer" "" | mm_has_transactions DE002
  # No POST route, so every YNAB request fails

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [ "$(grep -c "Error: YNAB API request failed." <<< "$output")" -eq 2 ]
  [ "$(posted_transactions | jq -c '[.[] | {account_id, import_id}]')" = '[{"account_id":"ynab-checking","import_id":"tx_101"},{"account_id":"ynab-savings","import_id":"tx_301"}]' ]
  [ -z "$(marked_as_synced)" ]
  [[ "$output" == *"Sync complete. 0 transaction(s) synced."* ]] || false
}

@test "Balance Sync reports a Balance Adjustment already imported today as skipped" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 123456789 10152.3 true | mm_has_accounts
  ynab_has_balance ynab-brokerage 10000000
  ynab_accepts_transactions 0 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"Adjustment of 152.30 was already imported today, skipped."* ]] || false
  [[ "$output" != *"balance adjustment(s) posted."* ]] || false
}

@test "sync totals Transaction Sync and Balance Sync mappings in its summary" {
  write_config "[
    {\"name\": \"Checking\", \"moneymoney_account\": \"DE001\", \"ynab_account_id\": \"$YNAB_CHECKING\"},
    $BROKERAGE_MAPPING
  ]"
  {
    mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries"
    mm_tx 102 2026-04-04 -9.99 true "" "Streaming Service" ""
  } | mm_has_transactions DE001
  mm_account 123456789 10152.3 true | mm_has_accounts
  ynab_has_balance ynab-brokerage 10000000
  ynab_accepts_transactions 2

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"Sync complete. 2 transaction(s) synced. 1 balance adjustment(s) posted."* ]] || false
}

@test "sync --dry-run totals Transaction Sync and Balance Sync mappings in its summary" {
  write_config "[
    {\"name\": \"Checking\", \"moneymoney_account\": \"DE001\", \"ynab_account_id\": \"$YNAB_CHECKING\"},
    $BROKERAGE_MAPPING
  ]"
  {
    mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries"
    mm_tx 102 2026-04-04 -9.99 true "" "Streaming Service" ""
  } | mm_has_transactions DE001
  mm_account 123456789 10152.3 true | mm_has_accounts
  ynab_has_balance ynab-brokerage 10000000

  run "$FLUSSO" sync --dry-run

  [ "$status" -eq 0 ]
  [[ "$output" == *"Dry run complete. 2 transaction(s) would be synced. 1 balance adjustment(s) would be posted."* ]] || false
  [ "$(posted_transactions)" = "[]" ]
}
