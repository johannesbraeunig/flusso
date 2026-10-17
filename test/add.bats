#!/usr/bin/env bats

load test_helper

@test "add appends a new Account Mapping and keeps the existing ones" {
  write_config
  local existing
  existing=$(jq -c '.accounts[0]' "$HOME/.flusso/config.json")
  ynab_has_budget
  mm_account 123456789 10000 true | mm_has_accounts

  run "$FLUSSO" add < <(balance_mapping_answers Brokerage 123456789 2; echo n)

  [ "$status" -eq 0 ]
  [[ "$output" == *"Config updated"* ]] || false
  [ "$(jq -c '.accounts' "$HOME/.flusso/config.json")" = "$(jq -c "[$existing, $BROKERAGE_MAPPING]" <<< null)" ]
  [ "$(jq -r '.api_token' "$HOME/.flusso/config.json")" = "test-token" ]
}

@test "add skips a MoneyMoney Account that is already configured and adds the new one" {
  write_config
  local existing
  existing=$(jq -c '.accounts[0]' "$HOME/.flusso/config.json")
  ynab_has_budget
  mm_account 123456789 10000 true | mm_has_accounts

  run "$FLUSSO" add < <(
    transaction_mapping_answers "Checking again" DE001 1; echo y
    balance_mapping_answers Brokerage 123456789 2; echo n
  )

  [ "$status" -eq 0 ]
  [[ "$output" == *'Skipping "Checking again" — already configured.'* ]] || false
  [ "$(jq -c '.accounts' "$HOME/.flusso/config.json")" = "$(jq -c "[$existing, $BROKERAGE_MAPPING]" <<< null)" ]
}

@test "add stops when the configured budget no longer exists in YNAB" {
  write_config
  local old_config
  old_config=$(cat "$HOME/.flusso/config.json")
  ynab_route GET /budgets '{"data": {"budgets": [{"id": "other-budget", "name": "Other"}]}}'

  run "$FLUSSO" add < /dev/null

  [ "$status" -eq 1 ]
  [[ "$output" == *"Configured budget not found in YNAB. Run 'flusso reset'."* ]] || false
  [ "$(cat "$HOME/.flusso/config.json")" = "$old_config" ]
}
