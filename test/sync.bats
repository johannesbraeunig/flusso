#!/usr/bin/env bats

load test_helper

@test "sync posts an Unsynced Transaction to YNAB and marks it as synced" {
  write_config
  mm_tx 101 2026-04-03 -42.5 true "" "Supermarket GmbH" "Groceries" | mm_has_transactions
  ynab_accepts_transactions 1

  run "$FLUSSO" sync

  [ "$status" -eq 0 ]
  [[ "$output" == *"1 created, 0 duplicates skipped."* ]]
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
