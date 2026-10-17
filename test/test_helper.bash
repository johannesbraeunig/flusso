# Shared setup for flusso tests: isolated HOME, fake osascript/curl on PATH,
# and builders for MoneyMoney and YNAB fixtures.

FLUSSO="$BATS_TEST_DIRNAME/../flusso"
SYNC_CATEGORY_UUID="11111111-2222-3333-4444-555555555555"
BUDGET_ID="budget-1"
YNAB_CHECKING="ynab-checking"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export FAKE_DIR="$BATS_TEST_TMPDIR/fake"
  mkdir -p "$HOME/.flusso" "$FAKE_DIR/mm" "$FAKE_DIR/ynab"
  : > "$FAKE_DIR/osascript.log"
  : > "$FAKE_DIR/curl.log"
  : > "$FAKE_DIR/ynab/routes"
  export PATH="$BATS_TEST_DIRNAME/fakes:$PATH"
}

# ── Config ──────────────────────────────────────────────────

# write_config [ACCOUNTS_JSON] [EXTRA_JSON]
# Default: one Account Mapping "Checking" (DE001 → $YNAB_CHECKING, Transaction Sync).
write_config() {
  local accounts="${1:-}" extra="${2:-}"
  [ -n "$accounts" ] || accounts="[{\"name\": \"Checking\", \"moneymoney_account\": \"DE001\", \"ynab_account_id\": \"$YNAB_CHECKING\"}]"
  [ -n "$extra" ] || extra='{}'
  jq -n \
    --arg budget "$BUDGET_ID" \
    --arg cat "$SYNC_CATEGORY_UUID" \
    --argjson accounts "$accounts" \
    --argjson extra "$extra" \
    '{api_token: "test-token", budget_id: $budget, start_date: "2026-04-01",
      sync_category: {uuid: $cat, name: "YNAB Synced"}, accounts: $accounts} + $extra' \
    > "$HOME/.flusso/config.json"
  chmod 600 "$HOME/.flusso/config.json"
}

# ── MoneyMoney fixtures ─────────────────────────────────────

# mm_tx ID DATE AMOUNT BOOKED CATEGORY_UUID NAME PURPOSE
# Prints one transaction <dict> as MoneyMoney's plist export does.
mm_tx() {
  local id="$1" date="$2" amount="$3" booked="$4"
  local category name purpose
  category=$(xml_escape "$5"); name=$(xml_escape "$6"); purpose=$(xml_escape "$7")
  cat <<EOF
		<dict>
			<key>accountUuid</key>
			<string>aaaaaaaa-0000-0000-0000-000000000001</string>
			<key>amount</key>
			<real>$amount</real>
			<key>booked</key>
			<$booked/>
			<key>bookingDate</key>
			<date>${date}T00:00:00Z</date>
			<key>categoryUuid</key>
			<string>$category</string>
			<key>currency</key>
			<string>EUR</string>
			<key>id</key>
			<integer>$id</integer>
			<key>name</key>
			<string>$name</string>
			<key>purpose</key>
			<string>$purpose</string>
			<key>valueDate</key>
			<date>${date}T00:00:00Z</date>
		</dict>
EOF
}

xml_escape() {
  printf '%s' "$1" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}

# mm_has_transactions < TX_DICTS
# Serves the given transaction dicts for every "export transactions" call.
mm_has_transactions() {
  {
    cat <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>creator</key>
	<string>MoneyMoney</string>
	<key>transactions</key>
	<array>
EOF
    cat
    cat <<'EOF'
	</array>
</dict>
</plist>
EOF
  } > "$FAKE_DIR/mm/export-transactions.plist"
}

# ── YNAB fixtures ───────────────────────────────────────────

# ynab_route METHOD PATH JSON
# Serves JSON for METHOD PATH (path relative to /v1, without query string).
ynab_route() {
  local file="$FAKE_DIR/ynab/response-$(wc -l < "$FAKE_DIR/ynab/routes" | tr -d ' ').json"
  printf '%s' "$3" > "$file"
  echo "$1 $2 $file" >> "$FAKE_DIR/ynab/routes"
}

# ynab_accepts_transactions [CREATED_COUNT] [DUPLICATE_COUNT]
ynab_accepts_transactions() {
  local created="${1:-1}" duplicates="${2:-0}"
  ynab_route POST "/budgets/$BUDGET_ID/transactions" "$(jq -cn \
    --argjson c "$created" --argjson d "$duplicates" \
    '{data: {transaction_ids: [range($c) | "ynab-tx-\(.)"], duplicate_import_ids: [range($d) | "dup-\(.)"]}}')"
}

# ── Call logs ───────────────────────────────────────────────

# Transactions posted to YNAB, as one JSON array across all POSTs.
posted_transactions() {
  jq -s '[.[] | select(.method == "POST") | .body.transactions // [.body.transaction] | .[]]' "$FAKE_DIR/curl.log"
}

# MoneyMoney transaction ids marked with the Sync Category, one per line.
marked_as_synced() {
  jq -r --arg cat "$SYNC_CATEGORY_UUID" \
    'select(.command == "set-transaction" and .category == $cat) | .id' "$FAKE_DIR/osascript.log"
}
