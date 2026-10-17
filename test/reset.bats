#!/usr/bin/env bats

load test_helper

new_setup_answers() {
  setup_answers new-token 2026-05-01 2 transaction_mapping_answers Checking DE001 1
}

@test "reset backs up the config after confirmation and runs setup" {
  write_config
  local old_config
  old_config=$(cat "$HOME/.flusso/config.json")
  setup_fixtures

  run "$FLUSSO" reset < <(printf 'y\n'; new_setup_answers)

  [ "$status" -eq 0 ]
  [ "$(cat "$HOME/.flusso/config.json.bak")" = "$old_config" ]
  [ "$(jq -r '.api_token + " " + .start_date' "$HOME/.flusso/config.json")" = "new-token 2026-05-01" ]
}

@test "reset changes nothing when not confirmed" {
  write_config
  local old_config
  old_config=$(cat "$HOME/.flusso/config.json")

  run "$FLUSSO" reset < <(printf 'n\n')

  [ "$status" -eq 0 ]
  [[ "$output" == *"Aborted. Nothing was changed."* ]] || false
  [ "$(cat "$HOME/.flusso/config.json")" = "$old_config" ]
  [ ! -f "$HOME/.flusso/config.json.bak" ]
}

@test "reset without a config starts a fresh setup without asking" {
  rm -rf "$HOME/.flusso"
  setup_fixtures

  run "$FLUSSO" reset < <(new_setup_answers)

  [ "$status" -eq 0 ]
  [[ "$output" == *"No existing configuration found"* ]] || false
  [ "$(jq -r '.api_token' "$HOME/.flusso/config.json")" = "new-token" ]
  [ ! -f "$HOME/.flusso/config.json.bak" ]
}
