#!/usr/bin/env bats

load test_helper

@test "setup writes the config with restricted permissions" {
  rm -rf "$HOME/.flusso"
  setup_fixtures

  run "$FLUSSO" setup < <(setup_answers test-token 2026-04-01 2 transaction_mapping_answers Checking DE001 1)

  [ "$status" -eq 0 ]
  [[ "$output" == *"Flusso is ready!"* ]] || false
  [ "$(jq -c . "$HOME/.flusso/config.json")" = "$(jq -cn --arg budget "$BUDGET_ID" --arg cat "$SYNC_CATEGORY_UUID" --arg acct "$YNAB_CHECKING" '{
    api_token: "test-token",
    budget_id: $budget,
    start_date: "2026-04-01",
    sync_category: {uuid: $cat, name: "YNAB Synced"},
    accounts: [{name: "Checking", moneymoney_account: "DE001", ynab_account_id: $acct}]
  }')" ]
  [ "$(stat -f '%Lp' "$HOME/.flusso")" = 700 ]
  [ "$(stat -f '%Lp' "$HOME/.flusso/config.json")" = 600 ]
}

@test "setup offers only open YNAB Accounts and non-group categories" {
  setup_fixtures

  run "$FLUSSO" setup < <(setup_answers test-token 2026-04-01 2 transaction_mapping_answers Checking DE001 1)

  [ "$status" -eq 0 ]
  [[ "$output" == *"[1]  Checking"*"[2]  Brokerage"* ]] || false
  [[ "$output" != *"Old Account"* ]] || false
  [[ "$output" == *"[1]  Groceries"*"[2]  YNAB Synced"* ]] || false
  [[ "$output" != *"Everyday"* ]] || false
}

@test "setup rejects an invalid token and writes no config" {
  # No YNAB routes, so the token check fails

  run "$FLUSSO" setup < <(printf '%s\n' bad-token)

  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Invalid token or YNAB API unreachable."* ]] || false
  [ ! -f "$HOME/.flusso/config.json" ]
}

@test "setup pre-selects Balance Sync for a Brokerage Account" {
  setup_fixtures
  mm_account 123456789 10000 true | mm_has_accounts

  run "$FLUSSO" setup < <(setup_answers test-token 2026-04-01 2 balance_mapping_answers Brokerage 123456789 2)

  [ "$status" -eq 0 ]
  [[ "$output" == *"This looks like a depot in MoneyMoney."* ]] || false
  [ "$(jq -c '.accounts' "$HOME/.flusso/config.json")" = "$(jq -c "[$BROKERAGE_MAPPING]" <<< null)" ]
}

@test "setup stores a custom start date for an Account Mapping" {
  setup_fixtures

  run "$FLUSSO" setup < <(setup_answers test-token 2026-04-01 2 transaction_mapping_answers Checking DE001 1 2026-03-01)

  [ "$status" -eq 0 ]
  [ "$(jq -r '.accounts[0].start_date' "$HOME/.flusso/config.json")" = 2026-03-01 ]
}

@test "setup warns about an account number that matches no MoneyMoney Account" {
  setup_fixtures
  mm_account DE999 100 false | mm_has_accounts

  run "$FLUSSO" setup < <(setup_answers test-token 2026-04-01 2 transaction_mapping_answers Checking DE001 1)

  [ "$status" -eq 0 ]
  [[ "$output" == *'Warning: No MoneyMoney account with number "DE001" found.'* ]] || false
}

@test "setup rejects an invalid start date" {
  setup_fixtures

  run "$FLUSSO" setup < <(printf '%s\n' test-token 1 April)

  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Invalid date format: April (expected YYYY-MM-DD)"* ]] || false
  [ ! -f "$HOME/.flusso/config.json" ]
}
