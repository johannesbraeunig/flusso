#!/usr/bin/env bats

load test_helper

# The one output line naming the Account Mapping; prints nothing if there isn't exactly one
status_line_for() {
  local lines
  lines=$(grep -F -- "$1" <<< "$output")
  [ "$(grep -c . <<< "$lines")" -eq 1 ] && echo "$lines"
}

@test "status counts Synced and Unsynced Transactions of a Transaction Sync mapping" {
  write_config
  {
    mm_tx 101 2026-04-03 -42.5 true "$SYNC_CATEGORY_UUID" "Supermarket GmbH" ""
    mm_tx 102 2026-04-04 -9.99 true "$SYNC_CATEGORY_UUID" "Streaming Service" ""
    mm_tx 103 2026-04-04 -29.99 true "" "Phone Provider" ""
    mm_tx 401 2026-04-05 -4.5 false "" "Cafe" ""
  } | mm_has_transactions

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Checking")" == *"2 synced, 1 unsynced"*"since 2026-04-01"* ]] || false
}

@test "status uses the Account Mapping's own start date" {
  write_config '[{"name": "Credit Card", "moneymoney_account": "1234****5678", "ynab_account_id": "ynab-card", "start_date": "2026-03-01"}]'
  mm_tx 201 2026-03-03 -9.99 true "" "Streaming Service" "" | mm_has_transactions

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Credit Card")" == *"0 synced, 1 unsynced"*"since 2026-03-01"* ]] || false
  [ "$(transaction_exports)" = "1234****5678 2026-03-01" ]
}

@test "status shows a Balance Sync mapping as in sync" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 123456789 10000 true | mm_has_accounts
  ynab_has_balance ynab-brokerage 10000000

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Brokerage")" == *"in sync at 10000.00"*"balance"* ]] || false
}

@test "status shows the amount a Balance Sync mapping would adjust" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 123456789 9847.7 true | mm_has_accounts
  ynab_has_balance ynab-brokerage 10000000

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Brokerage")" == *"-152.30 to adjust"* ]] || false
  [ "$(ynab_requests | jq '[.[] | select(.method == "POST")] | length')" -eq 0 ]
}

@test "status shows a Balance Sync mapping as unavailable when MoneyMoney can't be reached" {
  write_config "[$BROKERAGE_MAPPING]"
  # No account export fixture, so MoneyMoney's export fails
  ynab_has_balance ynab-brokerage 10000000

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Brokerage")" == *"unavailable"* ]] || false
}

@test "status shows a Balance Sync mapping as unavailable when YNAB can't be reached" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 123456789 10000 true | mm_has_accounts
  # No YNAB route, so the balance request fails

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Brokerage")" == *"unavailable"* ]] || false
}

@test "status still reports other Account Mappings when a MoneyMoney export fails" {
  write_config '[
    {"name": "Checking", "moneymoney_account": "DE001", "ynab_account_id": "ynab-checking"},
    {"name": "Savings", "moneymoney_account": "DE002", "ynab_account_id": "ynab-savings"}
  ]'
  # No fixture for DE001, so its export fails; status shows that as zero counts
  mm_tx 301 2026-04-03 100 true "$SYNC_CATEGORY_UUID" "Transfer" "" | mm_has_transactions DE002

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Checking")" == *"0 synced, 0 unsynced"* ]] || false
  [[ "$(status_line_for "Savings")" == *"1 synced, 0 unsynced"* ]] || false
}

@test "status still reports other Account Mappings when a MoneyMoney export can't be parsed" {
  write_config '[
    {"name": "Checking", "moneymoney_account": "DE001", "ynab_account_id": "ynab-checking"},
    {"name": "Savings", "moneymoney_account": "DE002", "ynab_account_id": "ynab-savings"}
  ]'
  mm_export_is_garbled DE001
  mm_tx 301 2026-04-03 100 true "" "Transfer" "" | mm_has_transactions DE002

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Checking")" == *"0 synced, 0 unsynced"* ]] || false
  [[ "$(status_line_for "Savings")" == *"0 synced, 1 unsynced"* ]] || false
}

@test "status shows a Balance Sync mapping as unavailable when MoneyMoney doesn't know the account" {
  write_config "[$BROKERAGE_MAPPING]"
  mm_account 999999999 10000 true | mm_has_accounts
  ynab_has_balance ynab-brokerage 10000000

  run "$FLUSSO" status

  [ "$status" -eq 0 ]
  [[ "$(status_line_for "Brokerage")" == *"unavailable"* ]] || false
}

@test "status rejects an invalid account number before calling MoneyMoney" {
  write_config '[{"name": "Checking", "moneymoney_account": "DE001\" & (do shell script \"id\") & \"", "ynab_account_id": "ynab-checking"}]'

  run "$FLUSSO" status

  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Invalid account identifier: DE001"* ]] || false
  [ -z "$(transaction_exports)" ]
}

@test "status rejects an invalid start date before calling MoneyMoney" {
  write_config '[{"name": "Checking", "moneymoney_account": "DE001", "ynab_account_id": "ynab-checking", "start_date": "April"}]'

  run "$FLUSSO" status

  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Invalid date format: April (expected YYYY-MM-DD)"* ]] || false
  [ -z "$(transaction_exports)" ]
}
